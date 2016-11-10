/*= require vue
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  window.gl.environmentsList.ActionsComponent = Vue.component('actions-component', {
    props: {
      actions: {
        type: Array,
        required: false,
        default: () => [],
      },
    },

    /**
     * Appends the svg icon that were render in the index page.
     * In order to reuse the svg instead of copy and paste in this template
     * we need to render it outside this component using =custom_icon partial.
     *
     * TODO: Remove this when webpack is merged.
     *
     */
    ready() {
      const playIcon = document.querySelector('.play-icon-svg.hidden svg');

      const dropdownContainer = this.$el.querySelector('.dropdown-play-icon-container');
      const actionContainers = this.$el.querySelectorAll('.action-play-icon-container');

      if (playIcon) {
        dropdownContainer.appendChild(playIcon.cloneNode(true));
        actionContainers.forEach((element) => {
          element.appendChild(playIcon.cloneNode(true));
        });
      }
    },

    template: `
      <div class="inline">
        <div class="dropdown">
          <a class="dropdown-new btn btn-default" data-toggle="dropdown">
            <span class="dropdown-play-icon-container">
              <!-- svg goes here -->
            </span>
            <i class="fa fa-caret-down"></i>
          </a>

          <ul class="dropdown-menu dropdown-menu-align-right">
            <li v-for="action in actions">
              <a :href="action.play_url" data-method="post" rel="nofollow">
              <span class="action-play-icon-container">
                <!-- svg goes here -->
              </span>
                <span>
                  {{action.name}}
                </span>
              </a>
            </li>
          </ul>
        </div>
      </div>
    `,
  });
})();