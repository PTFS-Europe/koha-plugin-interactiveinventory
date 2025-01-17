<template>
  <div :class="['item', { 'highlight': hasIssue }]" @click="toggleExpand">
    <p class="item-title">
      <span :class="issueIconClass" aria-hidden="true">{{ issueIcon }}</span>
      <span class="sr-only">{{ issueIconText }}</span>
      {{ item.biblio.title }} - {{ item.external_id }}
    </p>
    <div v-if="isExpanded" class="item-details">
      <div class="item-details-grid">
        <p><strong>Title:</strong></p><p>{{ item.biblio.title }}</p>
        <p><strong>Author:</strong></p><p>{{ item.biblio.author || 'N/A' }}</p>
        <p><strong>Publication Year:</strong></p><p>{{ item.biblio.publication_year || 'N/A' }}</p>
        <p><strong>Publisher:</strong></p><p>{{ item.biblio.publisher || 'N/A' }}</p>
        <p><strong>ISBN:</strong></p><p>{{ item.biblio.isbn || 'N/A' }}</p>
        <p><strong>Pages:</strong></p><p>{{ item.biblio.pages || 'N/A' }}</p>
        <p><strong>Location:</strong></p><p>{{ item.location }}</p>
        <p><strong>Acquisition Date:</strong></p><p>{{ item.acquisition_date }}</p>
        <p><strong>Last Seen Date:</strong></p><p>{{ item.last_seen_date }}</p>
        <p><strong>URL:</strong></p><p><a :href="constructedUrl" target="_blank" @click.stop>{{ constructedUrl }}</a></p>
        <p v-if="item.wasLost" class="item-warning"><strong>Warning:</strong></p><p v-if="item.wasLost" class="item-warning">This item was previously marked as lost. Reason: {{ lostReason }}</p>
        <p v-if="item.wrongPlace" class="item-warning"><strong>Warning:</strong></p><p v-if="item.wrongPlace" class="item-warning">This item may be in the wrong place. It is not in the list of expected items to be scanned.</p>
        <p v-if="item.checked_out_date" class="item-warning"><strong>Warning:</strong></p>
        <p v-if="item.checked_out_date" class="item-warning">
          This item was checked out on: {{ item.checked_out_date }} 
          <span v-if="sessionData.doNotCheckIn"> 
            and has not been checked in.
          </span>
          <span v-else>
            and has been checked in automatically.
          </span>
        </p>
        <p v-if="item.outOfOrder" class="item-warning"><strong>Warning:</strong></p><p v-if="item.outOfOrder" class="item-warning">This item has been scanned out of order. It should have been scanned before <a :href="highestCallNumberUrl" target="_blank" @click.stop>{{ currentItemWithHighestCallNumber }}</a>.
        </p>
        <p v-if="item.invalidStatus" class="item-warning"><strong>Warning:</strong></p><p v-if="item.invalidStatus" class="item-warning">This item has an invalid not for loan status. Please check it is correct using the link above.</p>
      </div>
    </div>
  </div>
</template>



<script>
import { EventBus } from './eventBus';

export default {
  props: {
    currentItemWithHighestCallNumber: String,
    currentBiblioWithHighestCallNumber: Number,
    sessionData: Object,
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
  created() {
    this.fetchAndSetAuthorizedValues('LOST');
  },
  computed: {
    highestCallNumberUrl() {
        return `/cgi-bin/koha/catalogue/detail.pl?biblionumber=${this.currentBiblioWithHighestCallNumber}`;
    },
    hasIssue() {
      return this.item.wasLost || this.item.wrongPlace || this.item.checked_out_date || this.item.outOfOrder || this.item.invalidStatus;
    },
    issueIcon() {
      return this.hasIssue ? '✖' : '✔';
    },
    issueIconClass() {
      return this.hasIssue ? 'text-danger' : 'text-success';
    },
    issueIconText() {
      return this.hasIssue ? 'Item has issues' : 'Item has no issues';
    },
    constructedUrl() {
      const biblionumber = this.item.biblio_id;
      return `${window.location.origin}/cgi-bin/koha/catalogue/detail.pl?biblionumber=${biblionumber}`;
    },
    lostReason() {
      const lostStatusValue = this.item.lost_status;
      const reason = this.authorizedValues[lostStatusValue];
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
      } else {
        try {
          const values = await this.fetchAuthorizedValues(field);

          // Directly use the values object
          this.authorizedValues = values;
          sessionStorage.setItem(cacheKey, JSON.stringify(values));
        } catch (error) {
          EventBus.emit('message', { type: 'error', text: 'Error setting authorized values' });
        }
      }
    },
  },
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

.item-warning {
  color: #ff6f61;
  font-weight: bold;
  grid-column: span 2;
}

.item-details-grid {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 3px;
  word-wrap: break-word; /* Ensure long text wraps within the column */
  overflow-wrap: break-word; /* Alternative property for word wrapping */
}
</style>