<template>
    <div v-if="message" :class="['message', message.type]">{{ message.text }}</div>
    <Inventory/>
</template>

<script>
import Inventory from './Inventory.vue'
import { EventBus } from './eventBus'

export default {
  name: 'Main',
  components: {
    Inventory
  },
  data() {
    return {
      message: null
    }
  },
  created() {
    EventBus.on('message', this.displayMessage);
  },
  methods: {
    displayMessage(message) {
      this.message = message;
      setTimeout(() => {
        this.message = null;
      }, 3000); // Hide after 3 seconds
    }
  },
  beforeDestroy() {
    EventBus.off('message', this.displayMessage);
  }
}
</script>
<style scoped>
.message {
  position: fixed;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  padding: 10px 20px;
  border-radius: 5px;
  z-index: 1000;
  animation: fadeOut 3s forwards;
}
.message.error {
  background-color: #f44336;
  color: white;
}
.message.status {
  background-color: #4caf50;
  color: white;
}
@keyframes fadeOut {
  0% { opacity: 1; }
  90% { opacity: 1; }
  100% { opacity: 0; }
}
</style>
