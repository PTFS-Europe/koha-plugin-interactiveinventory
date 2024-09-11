<template>
  <div class="container">
    <InventorySetupForm 
      @start-session="initiateInventorySession" 
      :fetchAuthorizedValues="fetchAuthorizedValues"
      v-if="!sessionStarted" />
    <div v-else>
      <form @submit.prevent="submitBarcode" class="barcode-form">
        <label for="barcode_input">Scan Barcode:</label>
        <input type="text" v-model="barcode" id="barcode_input" ref="barcodeInput" />
        <button type="submit">Submit</button>
      </form>
      <div id="inventory_results" class="items-list">
        <InventoryItem
          v-for="(item, index) in items"
          :key="`${index}-${item.id}`"
          :item="item"
          :index="index"
          :isExpanded="item.isExpanded"
          @toggleExpand="handleToggleExpand"
          :fetchAuthorizedValues="fetchAuthorizedValues"
          :currentItemWithHighestCallNumber="itemWithHighestCallNumber"
          :currentBiblioWithHighestCallNumber="biblioWithHighestCallNumber"
        />  
      </div>
      <button @click="exportToCSV">Export to CSV</button>
    </div>
  </div>
</template>

<script>
import InventorySetupForm from './InventorySetupForm.vue'
import InventoryItem from './InventoryItem.vue'

export default {
  components: {
    InventorySetupForm,
    InventoryItem
  },
  data() {
    return {
      barcode: '',
      items: [],
      sessionData: null,
      sessionStarted: false,
      highestCallNumberSort: '',
      itemWithHighestCallNumber: '',
      biblioWithHighestCallNumber: '',
    };
  },
  methods: {
    async fetchAuthorizedValues(category) {
      const response = await fetch(`/api/v1/authorised_value_categories/${category}/authorised_values`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      });
      if (!response.ok) {
        throw new Error(`Failed to fetch authorized values for ${category}`);
      }
      const data = await response.json();
      return data;
    },
    
    async submitBarcode() {
      try {
        // Fetch item data
        const itemResponse = await fetch(
          `/api/v1/items?external_id=${encodeURIComponent(this.barcode)}`,
          {
            method: 'GET',
            headers: {
              'Accept': 'application/json'
            }
          }
        );
        if (!itemResponse.ok) {
          throw new Error('Network response was not ok');
        }
        const itemText = await itemResponse.text();
        const itemsArray = itemText ? JSON.parse(itemText) : [];
        const itemData = itemsArray[0] || {};
        console.log('Item data:', itemData);

        // Fetch biblio data using biblio_id from item data
        const biblioResponse = await fetch(
          `/api/v1/biblios/${itemData.biblio_id}`,
          {
            method: 'GET',
            headers: {
              'Accept': 'application/json'
            }
          }
        );
        if (!biblioResponse.ok) {
          throw new Error('Network response was not ok');
        }
        const biblioText = await biblioResponse.text();
        const biblioData = biblioText ? JSON.parse(biblioText) : {};
        window.biblioData = biblioData;
        console.log('Biblio data:', biblioData);

        // Combine item data and biblio data
        const combinedData = { ...itemData, biblio: biblioData };

        // Add running 'fields to amend' variable
        var fieldsToAmend = {};

        if (this.sessionData.inventoryDate > combinedData.last_seen_date)
           fieldsToAmend["datelastseen"] = this.sessionData.inventoryDate;

        // If set to compare barcodes, check if the scanned barcode is in the expected list.
        // If not, show an alert and return.
        if (this.sessionData.compareBarcodes && !this.sessionData.response_data.rightPlaceList_data.includes(combinedData.external_id)) {
          combinedData.wrongPlace = true; // Flag the item as in the wrong place
        }

        if (combinedData.checked_out_date && !this.sessionData.doNotCheckIn){
          await this.checkInItem(combinedData.external_id);
        }

        // Check if the item is marked as lost and update its status
        if (combinedData.lost_status != "0") {
          combinedData.wasLost = true; // Flag the item as previously lost
          //add the key-value pair to the fields to amend object
          if (!this.sessionData.doNotCheckIn){
            fieldsToAmend["itemlost"] = '0';
          }
        }

        if (this.sessionData.checkShelvedOutOfOrder && combinedData.call_number_sort < this.highestCallNumberSort){
          combinedData.outOfOrder = 1;
        } else {
          this.highestCallNumberSort = combinedData.call_number_sort;
          this.itemWithHighestCallNumber = combinedData.external_id;
          this.biblioWithHighestCallNumber = combinedData.biblio_id;
        }


        window.combinedData = combinedData;

        // Prepend the combined data to the items array
        this.items.unshift(combinedData);

        // Set all items to be collapsed except the first one
        this.items = this.items.map((item, index) => ({
          ...item,
          isExpanded: index === 0 // Only expand the first item
        }));

        // Update the item status
        if (Object.keys(fieldsToAmend).length > 0){
          await this.updateItemStatus(combinedData.external_id, fieldsToAmend);
        }

        // Clear the barcode input and focus on it
        this.barcode = '';
        this.$refs.barcodeInput.focus();
      } catch (error) {
        console.error('There was a problem with the fetch operation:', error);
      }
    },
    async checkInItem(barcode) {
      try {
        const response = await fetch(
          `/api/v1/contrib/interactiveinventory/item/checkin`, 
          {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            barcode: barcode,
            date: this.sessionData.inventoryDate
          })
        });
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        console.log('Item checked in successfully');
      } catch (error) {
        console.error('There was a problem with the fetch operation:', error);
      }
    },
    async updateItemStatus(barcode, fields = {}) {
      try {
        console.log(this.sessionData);
        console.log('inventoryDate:', this.sessionData.inventoryDate);
        console.log(fields);
        const response = await fetch(
          `/api/v1/contrib/interactiveinventory/item/fields`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              barcode: barcode,
              fields: fields
            })
          }
        );
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        const data = await response.json();
        console.log('Item status updated:', data);
      } catch (error) {
        console.error('There was a problem with the fetch operation:', error);
      }
    },
    async initiateInventorySession(sessionData) {
      this.sessionData = sessionData;
      this.sessionStarted = true;
      try {
        const response = await fetch(
          `/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::Com::InteractiveInventory&method=start_session&session_data=${encodeURIComponent(JSON.stringify(sessionData))}`,
          {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json'
            }
          }
        );
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        const data = await response.json();
        console.log('Session started:', data);
        this.sessionData.response_data = data; // Add this line to include the response data in sessionData

      } catch (error) {
        console.error('There was a problem with the fetch operation:', error);
      }
    },
    handleToggleExpand(itemId) {
      this.items = this.items.map((item, index) => ({
        ...item,
        isExpanded: `${index}-${item.id}` === itemId ? !item.isExpanded : false // Toggle the clicked item, collapse others
      }));
    },
    fetchAuthorizedValues(field) {
      return fetch(`/api/v1/authorised_value_categories/${field}/authorised_values`)
        .then(response => response.json())
        .then(data => {
          const values = {};
          data.forEach(item => {
            values[item.value] = item.description;
          });
          return values;
        })
        .catch(error => {
          console.error('Error fetching authorized values:', error);
          throw error;
        });
    },
    exportToCSV() {
      const headers = [
        'Item_ID', 'Biblio_ID', 'Title', 'Author', 'Publication Year', 
        'Publisher', 'ISBN', 'Pages', 'Location', 'Acquisition Date', 'Last Seen Date', 'URL', 'Was Lost', 'Lost Reason'
      ];

      const csvContent = [
        headers.join(','),
        ...this.items.map(item => {
          return [
            `"${item.item_id}"`,
            `"${item.biblio_id}"`,
            `"${item.biblio.title}"`,
            `"${item.biblio.author || 'N/A'}"`,
            `"${item.biblio.publication_year || 'N/A'}"`,
            `"${item.biblio.publisher || 'N/A'}"`,
            `"${item.biblio.isbn || 'N/A'}"`,
            `"${item.biblio.pages || 'N/A'}"`,
            `"${item.location}"`,
            `"${item.acquisition_date}"`,
            `"${item.last_seen_date}"`,
            `"${window.location.origin}/cgi-bin/koha/catalogue/detail.pl?biblionumber=${item.biblio_id}"`,
            `"${item.wasLost ? 'Yes' : 'No'}"`,
            `"${item.wasLost ? item.lostReason : 'N/A'}"`
          ].join(',');
        })
      ].join('\n');

      const blob = new Blob([csvContent], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'inventory.csv';
      a.click();
      URL.revokeObjectURL(url);
    }
  }
}
</script>

<style scoped>
.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  font-family: Arial, sans-serif;
}

.barcode-form {
  display: flex;
  flex-direction: column;
  margin-bottom: 20px;
}

.barcode-form label {
  margin-bottom: 5px;
  font-weight: bold;
}

.barcode-form input {
  padding: 10px;
  margin-bottom: 10px;
  border: 1px solid #ccc;
  border-radius: 4px;
}

.barcode-form button {
  padding: 10px 20px;
  border: none;
  background-color: #007bff;
  color: white;
  border-radius: 4px;
  cursor: pointer;
}

.barcode-form button:hover {
  background-color: #0056b3;
}

.items-list {
  margin-top: 20px;
}
</style>