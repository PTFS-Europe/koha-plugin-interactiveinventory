<template>
  <div class="container">
    <InventorySetupForm @start-session="initiateInventorySession" v-if="!sessionStarted" />
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
        />  
      </div>
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
      sessionStarted: false
    }
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
      return response.json();
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

        // Check if the item is marked as lost and update its status
        if (combinedData.lost_status != "0") {
          await this.updateItemStatus(combinedData.external_id);
          combinedData.wasLost = true; // Flag the item as previously lost
        }

        window.combinedData = combinedData;

        // Prepend the combined data to the items array
        this.items.unshift(combinedData);

        // Set all items to be collapsed except the first one
        this.items = this.items.map((item, index) => ({
          ...item,
          isExpanded: index === 0 // Only expand the first item
        }));

        // Clear the barcode input and focus on it
        this.barcode = '';
        this.$refs.barcodeInput.focus();
      } catch (error) {
        console.error('There was a problem with the fetch operation:', error);
      }
    },
    async updateItemStatus(barcode) {
      try {
        const response = await fetch(
          `/api/v1/contrib/interactiveinventory/item/fields`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              barcode: barcode,
              fields: {
                itemlost: '0'
              }
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