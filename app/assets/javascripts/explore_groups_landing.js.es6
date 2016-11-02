/* global Cookies */

(() => {
  const global = window.gl || (window.gl = {});
  const COOKIE_NAME = 'explore_groups_landing_dismissed';

  class ExploreGroupsLanding {
    constructor() {
      this.landing = document.querySelector('.js-explore-groups-landing');
      this.dismissButton = this.landing.querySelector('.dismiss-icon');
      this.initDismissButton();
    }

    initDismissButton() {
      const isDismissed = !!Cookies.get(COOKIE_NAME);
      console.log(isDismissed, 'isDismissed');
      this.landing.classList.toggle('hidden', isDismissed);
      if (!isDismissed) this.dismissButton.addEventListener('click', this.dismissLanding.bind(this));
    }

    dismissLanding() {
      this.landing.classList.add('hidden');
      Cookies.set(COOKIE_NAME, true);
    }
  }

  global.ExploreGroupsLanding = ExploreGroupsLanding;
})();
