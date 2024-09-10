<template>
  <Inventory :csrfToken="csrfToken" />
</template>

<script>
import Inventory from './Inventory.vue'

export default {
  name: 'Main',
  components: {
    Inventory
  },
  data() {
    return {
      csrfToken: window.csrf_token // Access the CSRF token from the global scope
    }
  }
}
</script>
