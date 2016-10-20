//= require vue
//= require_tree .

$(() => {
  const EMPTY_DIALOG_COOKIE = 'ca_empty_dialog_dismissed';
  const OVERVIEW_DIALOG_COOKIE = 'ca_overview_dialog_dismissed';
  const cycleAnalyticsEl = document.querySelector('#cycle-analytics');
  const cycleAnalyticsStore = gl.cycleAnalytics.CycleAnalyticsStore;
  const cycleAnalyticsService = new gl.cycleAnalytics.CycleAnalyticsService({
    requestPath: cycleAnalyticsEl.dataset.requestPath,
  });

  gl.cycleAnalyticsApp = new Vue({
    el: '#cycle-analytics',
    name: 'CycleAnalytics',
    data: {
      state: cycleAnalyticsStore.state,
      isLoading: false,
      isLoadingStage: false,
      isEmptyStage: false,
      startDate: 30,
      isEmptyDialogDismissed: Cookies.get(EMPTY_DIALOG_COOKIE),
      isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
    },
    computed: {
      currentStage() {
        return cycleAnalyticsStore.currentActiveStage();
      },
    },
    components: {
      'stage-button': gl.cycleAnalytics.StageButton,
      'stage-issue-component': gl.cycleAnalytics.StageIssueComponent,
      'stage-plan-component': gl.cycleAnalytics.StagePlanComponent,
      'stage-code-component': gl.cycleAnalytics.StageCodeComponent,
      'stage-test-component': gl.cycleAnalytics.StageTestComponent,
      'stage-review-component': gl.cycleAnalytics.StageReviewComponent,
      'stage-staging-component': gl.cycleAnalytics.StageStagingComponent,
      'stage-production-component': gl.cycleAnalytics.StageProductionComponent,
    },
    created() {
      this.fetchCycleAnalyticsData();
    },
    methods: {
      handleError() {
        cycleAnalyticsStore.setErrorState(true);
        return new Flash('There was an error while fetching cycle analytics data.');
      },
      initDropdown() {
        const $dropdown = $('.js-ca-dropdown');
        const $label = $dropdown.find('.dropdown-label');

        $dropdown.find('li a').off('click').on('click', (e) => {
          e.preventDefault();
          const $target = $(e.currentTarget);
          this.startDate = $target.data('value');

          $label.text($target.text().trim());
          this.fetchCycleAnalyticsData({ startDate: this.startDate });
        });
      },
      fetchCycleAnalyticsData(options) {
        const fetchOptions = options || { startDate: this.startDate };

        this.isLoading = true;

        cycleAnalyticsService
          .fetchCycleAnalyticsData(fetchOptions)
          .done((response) => {
            cycleAnalyticsStore.setCycleAnalyticsData(response);
            this.selectDefaultStage();
            this.initDropdown();
          })
          .error(() => {
            this.handleError();
          })
          .always(() => {
            this.isLoading = false;
          });
      },
      selectDefaultStage() {
        this.selectStage(this.state.stages.first());
      },
      selectStage(stage) {
        if (this.isLoadingStage) return;
        if (this.currentStage === stage) return;

        this.isLoadingStage = true;
        cycleAnalyticsStore.setStageItems([]);
        cycleAnalyticsStore.setActiveStage(stage);

        cycleAnalyticsService
          .fetchStageData({
            stage,
            startDate: this.startDate,
          })
          .done((response) => {
            this.isEmptyStage = !response.items.length;
            cycleAnalyticsStore.setStageItems(response.items);
          })
          .error(() => {
            this.isEmptyStage = true;
          })
          .always(() => {
            this.isLoadingStage = false;
          });
      },
      dismissEmptyDialog() {
        this.isEmptyDialogDismissed = true;
        Cookies.set(EMPTY_DIALOG_COOKIE, '1');
      },
      dismissOverviewDialog() {
        this.isOverviewDialogDismissed = true;
        Cookies.set(OVERVIEW_DIALOG_COOKIE, '1');
      },
    },
  });
});
