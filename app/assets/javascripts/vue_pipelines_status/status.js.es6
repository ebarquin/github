/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStatusScope = Vue.extend({
    components: {
      'vue-running-scope': gl.VueRunningScope,
      'vue-pending-scope': gl.VuePendingScope,
      'vue-failed-scope': gl.VueFailedScope,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <vue-running-scope
          v-if="pipeline.details.status === 'running'"
          :pipeline='pipeline'
        >
        </vue-running-scope>
        <vue-pending-scope
          v-if="pipeline.details.status === 'pending'"
          :pipeline='pipeline'
        >
        </vue-pending-scope>
        <vue-failed-scope
          v-if="pipeline.details.status === 'failed'"
          :pipeline='pipeline'
        >
        </vue-failed-scope>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));