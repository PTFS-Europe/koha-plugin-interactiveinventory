<style scoped>
.test {
  color: red;
}
</style>

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
        <div v-for="item in items" :key="item.barcode">
          <p>{{ item.title }} - {{ item.status }}</p>
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
      sessionStarted: false,
      sessionData: {},
      csrfToken: window.csrf_token,
    }
  },
  methods: {
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
    const data = await response.json()
    console.log('Session started:', data)
  } catch (error) {
    console.error('There was a problem with the fetch operation:', error)
  }
},
    async submitBarcode() {
      try {
        const response = await fetch(
          `/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::Com::InteractiveInventory&method=get_item_data&barcode=${encodeURIComponent(this.barcode)}`,
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
        const data = await response.json()
        this.items.push(data)
      } catch (error) {
        console.error('There was a problem with the fetch operation:', error)
      }
    }
  }
}
</script>

<style scoped>
form {
  display: flex;
  flex-direction: column;
}
label {
  margin-top: 10px;
}
button {
  margin-top: 20px;
}
</style>
