<template>
  <div>
    <InventorySetupForm @start-session="initiateInventorySession" v-if="!sessionStarted" />
    <div v-else>
      <form @submit.prevent="submitBarcode">
        <label for="barcode_input">Scan Barcode:</label>
        <input type="text" v-model="barcode" id="barcode_input" />
        <button type="submit">Submit</button>
      </form>
      <div id="inventory_results">
        <div v-for="item in items" :key="item.external_id">
          <p>{{ item.biblio.title }} - {{ item.external_id }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import InventorySetupForm from './InventorySetupForm.vue'

export default {
  components: {
    InventorySetupForm
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
    async submitBarcode() {
      try {
        // Fetch item data
        const itemResponse = await fetch(
          `/api/v1/items?external_id=${encodeURIComponent(this.barcode)}`,
          {
            method: 'GET',
            // headers: {
            //   'Content-Type': 'application/json'
            // }
          }
        )
        if (!itemResponse.ok) {
          throw new Error('Network response was not ok')
        }
        const itemText = await itemResponse.text();
        const itemsArray = itemText ? JSON.parse(itemText) : [];
        const itemData = itemsArray[0] || {};
        console.log('Item data:', itemData)

        // Fetch biblio data using biblio_id from item data
        const biblioResponse = await fetch(
          `/api/v1/biblios/${itemData.biblio_id}`,
          {
            method: 'GET',
            headers: {
              'Accept': 'application/json'
            }
          }
        )
        if (!biblioResponse.ok) {
          throw new Error('Network response was not ok')
        }
       const biblioText = await biblioResponse.text();
        const biblioData = biblioText ? JSON.parse(biblioText) : {};
        window.biblioData = biblioData;
        console.log('Biblio data:', biblioData)

        // Combine item data and biblio data
        const combinedData = { ...itemData, biblio: biblioData };
        window.combinedData = combinedData;

        // Prepend the combined data to the items array
        this.items.unshift(combinedData);
      } catch (error) {
        console.error('There was a problem with the fetch operation:', error)
      }
    },
    async initiateInventorySession(sessionData) {
      this.sessionData = sessionData
      this.sessionStarted = true
      try {
        const response = await fetch(
          `/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::Com::InteractiveInventory&method=start_session&session_data=${encodeURIComponent(JSON.stringify(sessionData))}`,
          {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json'
            }
          }
        )
        if (!response.ok) {
          throw new Error('Network response was not ok')
        }
        const data = await response.json();
        console.log('Session started:', data);
      } catch (error) {
        console.error('There was a problem with the fetch operation:', error);
      }
    }
  }
}
</script>

<style scoped>
form {
  display: flex;
}
</style>