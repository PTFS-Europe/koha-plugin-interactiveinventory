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
    isExpanded: Boolean,
    index: Number
  },
  methods: {
    toggleExpand() {
      this.$emit('toggleExpand', `${this.index}-${this.item.id}`);
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
</style>