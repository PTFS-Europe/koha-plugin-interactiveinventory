<template>

    <form @submit.prevent="startInventorySession">
      <div class="form-group">
        <label for="library">Library</label>
        <select v-model="selectedLibraryId" id="library" class="form-control">
          <option value="">All Libraries</option>
          <option v-for="library in libraries" :key="library.id" :value="library.id">
            {{ library.name }}
          </option>
        </select>
      </div>
      <div>
        <label for="locationloop">Location Loop:</label>
        <select id="locationloop" v-model="locationLoop">
          <!-- Options here -->
        </select>
      </div>
      <div class="form-group">
        <label for="collectionCode">Collection Code</label>
        <select v-model="ccode" id="collectionCode" class="form-control">
          <option value="" disabled>Select a collection code</option>
          <option v-for="ccode, key in collectionCodes" :key="key" :value="key">{{ ccode }}</option>
        </select>
      </div>
      <div>
        <label for="minlocation">Item call number between:</label>
        <input type="text" id="minlocation" v-model="minLocation" /> (items.itemcallnumber)
      </div>
      <div>
        <label for="maxlocation">...and:</label>
        <input type="text" id="maxlocation" v-model="maxLocation" />
      </div>
      <div>
      <label for="class_source">Call number classification scheme:</label>
    <select id="class_source" v-model="classSource">
      <option v-for="(source, key) in classSources" :key="key" :value="key">{{ source.description }}</option>
    </select>
  </div>
      <fieldset class="rows" id="optionalfilters">
        <legend>Optional filters for inventory list or comparing barcodes</legend>
        <span class="hint">Scanned items are expected to match one of the selected "not for loan" criteria if any are checked.</span>
        <br/>
        <div id="statuses" class="statuses-grid">
          <div v-for="(statusList, statusKey) in statuses" :key="statusKey" class="status-column">
            <label :for="statusKey">{{ statusKey }}:</label>
            <div v-for="status in statusList" :key="statusKey + '-' + status.authorised_value_id" class="status-row">
              <input type="checkbox" :id="statusKey + '-' + status.authorised_value_id" :value="status.authorised_value_id" v-model="selectedStatuses[statusKey]" />
              <label :for="statusKey + '-' + status.authorised_value_id">{{ status.description }}</label>
            </div>
          </div>
        </div>
      </fieldset>
      <ol>
        <li>
          <label for="datelastseen">Last inventory date:</label>
          <input type="text" id="datelastseen" v-model="dateLastSeen" class="flatpickr" />
          (Skip records marked as seen on or after this date.)
        </li>
        <li>
          <label for="ignoreissued">Skip items on loan: </label>
          <input type="checkbox" id="ignoreissued" v-model="ignoreIssued" />
        </li>
        <li>
          <label for="ignore_waiting_holds">Skip items on hold awaiting pickup: </label>
          <input type="checkbox" id="ignore_waiting_holds" v-model="ignoreWaitingHolds" />
        </li>
      </ol>
      <button type="submit">Submit</button>
    </form>
</template>

<script>
export default {
  props: {
    fetchAuthorizedValues: {
      type: Function,
      required: true
    },
  },
  data() {
    const classSources = window.class_sources || {};
    const defaultClassSource = Object.keys(classSources).find(key => classSources[key].default === 1) || '';
    return {
      branchLoop: '',
      locationLoop: '',
      ccode: '',
      minLocation: '',
      maxLocation: '',
      classSource: defaultClassSource,
      selectedStatuses: {
        'items.itemlost': [],
        'items.notforloan': [],
        'items.withdrawn': [],
        'items.damaged': []
      },
      dateLastSeen: '',
      ignoreIssued: false,
      ignoreWaitingHolds: false,
      statuses: {},
      libraries: [],
      selectedLibraryId: '',
      collectionCodes: [],
      classSources: window.class_sources, 
    };
  },
  created() {
    this.createStatuses();
    this.fetchLibraries();
    this.fetchCollectionCodes();
  },
  methods: {
    checkForm() {
      if (!(this.branchLoop || this.locationLoop || this.ccode || this.minLocation || this.maxLocation || this.classSource || this.selectedStatuses.length)) {
        return confirm(
          "You have not selected any catalog filters and are about to compare a file of barcodes to your entire catalog.\n\n" +
          "For large catalogs this can result in unexpected behavior\n\n" +
          "Are you sure you want to do this?"
        );
      }
      return true;
    },
    startInventorySession() {
      // Pass the values to the inventory script
      this.$emit('start-session', {
        minLocation: this.minLocation,
        maxLocation: this.maxLocation,
        locationLoop: this.locationLoop,
        branchLoop: this.branchLoop,
        dateLastSeen: this.dateLastSeen,
        ccode: this.ccode,
        classSource: this.classSource,
        selectedStatuses: this.selectedStatuses,
        ignoreIssued: this.ignoreIssued,
        ignoreWaitingHolds: this.ignoreWaitingHolds
      });
    },
    async createStatuses() {
    try {
      const statusFields = {
        'items.itemlost': 'LOST',
        'items.notforloan': 'NOT_LOAN',
        'items.withdrawn': 'WITHDRAWN',
        'items.damaged': 'DAMAGED'
      };

      const statusPromises = Object.values(statusFields).map(field => this.fetchAuthorizedValues(field));
      const statusResults = await Promise.all(statusPromises);

      Object.keys(statusFields).forEach((key, index) => {
        let result = statusResults[index];
        if (result && typeof result === 'object' && !Array.isArray(result)) {
          result = Object.keys(result).map(k => ({
            value: k,
            description: result[k]
          }));
        }

        if (Array.isArray(result)) {
          this.statuses[key] = result.map(item => ({
            authorised_value_id: item.value,
            description: item.description
          }));
        } else {
          console.error(`Unexpected result format for ${statusFields[key]}:`, result);
        }
      });

      console.log('Statuses:', this.statuses);
    } catch (error) {
      console.error('Error creating statuses:', error);
    }
  },
  async fetchLibraries() {
      try {
        const response = await fetch('/api/v1/public/libraries');
        const data = await response.json();
        this.libraries = data;
      } catch (error) {
        console.error('Error fetching libraries:', error);
      }
    },
    async fetchCollectionCodes() {
      try {
        const collectionCodes = await this.fetchAuthorizedValues('CCODE');
        this.collectionCodes = collectionCodes;
      } catch (error) {
        console.error(error);
      }
    },
  },
  
};
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
.statuses-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr); /* Ensure all columns fit in one row */
  gap: 16px;
}

.status-column {
  display: flex;
  flex-direction: column;
}

.status-row {
  display: flex;
  align-items: center;
  margin-bottom: 8px;
}

.status-row label {
  font-weight: normal; /* Ensure labels are not bold */
}
.form-group {
  margin-bottom: 1rem;
}

.form-control {
  width: 100%;
  padding: 0.375rem 0.75rem;
  font-size: 1rem;
  line-height: 1.5;
  color: #495057;
  background-color: #fff;
  background-clip: padding-box;
  border: 1px solid #ced4da;
  border-radius: 0.25rem;
  transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
}

.form-control:focus {
  border-color: #80bdff;
  outline: 0;
  box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
}
</style>
