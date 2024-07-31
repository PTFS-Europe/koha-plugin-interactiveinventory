<template>
  <div :class="['item', { 'highlight': item.wasLost }]" @click="toggleExpand">
    <p class="item-title">{{ item.biblio.title }} - {{ item.external_id }}</p>
    <div v-if="isExpanded" class="item-details">
      <p><strong>Title:</strong> {{ item.biblio.title }}</p>
      <p><strong>Author:</strong> {{ item.biblio.author || 'N/A' }}</p>
      <p><strong>Publication Year:</strong> {{ item.biblio.publication_year || 'N/A' }}</p>
      <p><strong>Publisher:</strong> {{ item.biblio.publisher || 'N/A' }}</p>
      <p><strong>ISBN:</strong> {{ item.biblio.isbn || 'N/A' }}</p>
      <p><strong>Pages:</strong> {{ item.biblio.pages || 'N/A' }}</p>
      <p><strong>Location:</strong> {{ item.location }}</p>
      <p><strong>Acquisition Date:</strong> {{ item.acquisition_date }}</p>
      <p><strong>Last Seen Date:</strong> {{ item.last_seen_date }}</p>
      <p><strong>URL:</strong> <a :href="constructedUrl" target="_blank">{{ constructedUrl }}</a></p>
      <p v-if="item.wasLost" class="lost-item-warning"><strong>Warning:</strong> This item was previously marked as lost. Reason: {{ lostReason }}</p>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    item: Object,
    isExpanded: Boolean,
    index: Number,
    fetchAuthorizedValues: {
      type: Function,
      required: true
    }
  },
  data() {
    return {
      authorizedValues: {}
    };
  },
  computed: {
    constructedUrl() {
      const biblionumber = this.item.biblio_id;
      return `${window.location.origin}/cgi-bin/koha/catalogue/detail.pl?biblionumber=${biblionumber}`;
    },
    lostReason() {
      const lostStatusValue = this.item.lost_status;
      console.log('Item lost status value:', lostStatusValue);
      console.log('Authorized values:', this.authorizedValues);
      const reason = this.authorizedValues[lostStatusValue];
      console.log('Resolved reason:', reason);
      return reason || 'Unknown';
    }
  },
  methods: {
    toggleExpand() {
      this.$emit('toggleExpand', `${this.index}-${this.item.id}`);
    },
    async fetchAndSetAuthorizedValues(field) {
      const cacheKey = `authorizedValues_${field}`;
      const cachedValues = sessionStorage.getItem(cacheKey);

      if (cachedValues) {
        this.authorizedValues = JSON.parse(cachedValues);
        console.log('Using cached authorized values:', this.authorizedValues);
      } else {
        try {
          const values = await this.fetchAuthorizedValues(field);
          const parsedValues = values.reduce((acc, item) => {
            acc[item.value] = item.description;
            return acc;
          }, {});
          this.authorizedValues = parsedValues;
          sessionStorage.setItem(cacheKey, JSON.stringify(parsedValues));
          console.log('Fetched and cached authorized values:', this.authorizedValues);
        } catch (error) {
          console.error('Error setting authorized values:', error);
        }
      }
    }
  },
  created() {
    this.fetchAuthorizedValues();
  }
}
</script>

<style scoped>
.item {
  padding: 15px;
  border: 1px solid #ddd;
  border-radius: 5px;
  margin-bottom: 15px;
  background-color: #fff;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.item:hover {
  background-color: #f1f1f1;
}

.item-title {
  font-size: 1.2em;
  font-weight: bold;
  margin-bottom: 10px;
}

.item-details {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid #eee;
}

.item-details p {
  margin: 5px 0;
}

.item-details p strong {
  display: inline-block;
  width: 150px;
}

.item-details a {
  color: #007bff;
  text-decoration: none;
}

.item-details a:hover {
  text-decoration: underline;
}

.highlight {
  border-color: #ff6f61;
}

.lost-item-warning {
  color: #ff6f61;
  font-weight: bold;
}
</style>