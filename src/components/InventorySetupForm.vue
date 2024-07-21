<template>
  <div>
    <form @submit.prevent="startInventorySession">
      <label for="minlocation">Min Location:</label>
      <input type="text" v-model="minlocation" id="minlocation" required />

      <label for="maxlocation">Max Location:</label>
      <input type="text" v-model="maxlocation" id="maxlocation" required />

      <label for="location">Location:</label>
      <input type="text" v-model="location" id="location" required />

      <label for="branchcode">Branch Code:</label>
      <input type="text" v-model="branchcode" id="branchcode" required />

      <label for="datelastseen">Date Last Seen:</label>
      <input type="date" v-model="datelastseen" id="datelastseen" required />

      <label for="ccode">Collection Code:</label>
      <input type="text" v-model="ccode" id="ccode" required />

      <label for="itemtypes">Item Types:</label>
      <input type="text" v-model="itemtypes" id="itemtypes" required />

      <button type="submit">Start Inventory Session</button>
    </form>
  </div>
</template>

<script>
export default {
  data() {
    return {
      minlocation: '',
      maxlocation: '',
      location: '',
      branchcode: '',
      datelastseen: '',
      ccode: '',
      itemtypes: ''
    }
  },
  methods: {
    startInventorySession() {
      // Pass the values to the inventory script
      this.$emit('start-session', {
        minlocation: this.minlocation,
        maxlocation: this.maxlocation,
        location: this.location,
        branchcode: this.branchcode,
        datelastseen: this.datelastseen,
        ccode: this.ccode,
        itemtypes: this.itemtypes
      })
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
