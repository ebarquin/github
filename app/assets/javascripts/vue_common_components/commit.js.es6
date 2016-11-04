//= require vue

(() => {
  window.gl = window.gl || {};

  window.gl.commitComponent = Vue.component('commit-component', {

    props: {
      /**
       * Indicates the existance of a tag.
       * Used to render the correct icon, if true will render `fa-tag` icon,
       * if false will render `fa-code-fork` icon.
       */
      tag: {
        type: Boolean,
        required: true,
      },

      /**
       * If provided is used to render the branch name and url.
       * Should contain the following properties:
       * name
       * ref_url
       */
      ref: {
        type: Object,
        required: false,
        default: {},
      },

      /**
       * Used to link to the commit sha.
       */
      commit_url: {
        type: String,
        required: true,
      },

      /**
       * Used to show the commit short_sha that links to the commit url.
       */
      short_sha: {
        type: String,
        required: true,
      },

      /**
       * If provided shows the commit tile.
       */
      title: {
        type: String,
        required: false,
      },

      /**
       * If provided renders information about the author of the commit.
       * When provided should include:
       * `avatar_url` to render the avatar icon
       * `web_url` to link to user profile
       * `username` to render alt and title tags
       */
      author: {
        type: Object,
        required: false,
      },
    },

    computed: {
      /**
       * Used to verify if all the properties needed to render the commit
       * ref section were provided.
       *
       * TODO: Improve this! Use lodash when we have it.
       *
       * @returns {Boolean}
       */
      hasRef() {
        return this.ref && this.ref.name && this.ref.ref_url;
      },

      /**
       * Used to verify if all the properties needed to render the commit
       * author section were provided.
       *
       * TODO: Improve this! Use lodash when we have it.
       *
       * @returns {Boolean}
       */
      hasAuthor() {
        return this.author && this.author.avatar_url && this.author.web_url && this.author.username;
      },

      /**
       * If information about the author is provided will return a string
       * to be rendered as the alt attribute of the img tag.
       *
       * TODO: Improve this!
       * @returns {String}
       */
      userImageAltDescription() {
        return this.author && this.author.username ? `${this.author.username}'s avatar` : null;
      },
    },

    /**
     * In order to reuse the svg instead of copy and paste in this template the html_safe
     * we need to render it outside this component using =custom_icon partial.
     * Make sure it has this structure:
     * .commit-icon-svg.hidden
     *   svg
     *
     * TODO: Find a better way to include SVG
     */
    mount() {
      const commitIconSVG = document.querySelector('.commit-icon-svg.hidden svg');

      document.querySelector('.branch-commit .commit-icon-container').innerHtml = commitIconSVG;
    },

    template: `
      <div class="branch-commit">
        <div v-if='hasRef'>
          <div class="icon-container">
            <i v-if='tag' class="fa fa-tag"></i>
            <i v-else class="fa fa-code-fork"></i>
          </div>

          <a class="monospace branch-name" :href='ref.ref_url'>
            {{ref.name}}
          </a>
        </div>

        <div class="icon-container commit-icon commit-icon-container">
          <!-- svg goes here -->
        </dvi>

        <a class="commit-id monospace" :url='commit_url'>
          {{short_sha}}
        </a>

        <p class="commit-title">
          <span v-if='title && hasAuthor'>
            <!-- commit author info-->
            <a :href='author.web_url'>
              <img
                class="avatar has-tooltip s20"
                :alt='userImageAltDescription'
                :title='author.username'
                :src='author.author_avatar'/>
            </a>

            <a class="commit-row-message" :href='commit_url'>
              {{title}}
            </a>
          </span>
          <span v-else>
            Cant find HEAD commit for this branch
          </span>
        </p>
      </div>
    `,
  });
})();
