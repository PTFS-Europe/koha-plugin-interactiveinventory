<template>
    <div :class="['item', { 'highlight': item.wasLost }]" @click="toggleExpand">
      <p>{{ item.biblio.title }} - {{ item.external_id }}</p>
      <div v-if="isExpanded" class="item-details">
        <p>Additional details about the item...</p>
        <!-- Add more details as needed -->
      </div>
    </div>
  </template>
  
  <script>
  export default {
    props: {
      item: Object,
      isInitiallyExpanded: Boolean
    },
    data() {
      return {
        isExpanded: this.isInitiallyExpanded
      }
    },
    methods: {
      toggleExpand() {
        this.isExpanded = !this.isExpanded;
      }
    }
  }
  </script>
  
  <style scoped>
  .item {
    padding: 10px;
    border: 1px solid #ccc;
    border-radius: 4px;
    margin-bottom: 10px;
    background-color: #f9f9f9;
    cursor: pointer;
  }
  
  .item.highlight {
    background-color: #ffeb3b;
  }
  
  .item-details {
    margin-top: 10px;
  }
  </style>