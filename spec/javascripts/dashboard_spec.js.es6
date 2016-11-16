/*= require sidebar */
/*= require js.cookie */
/*= require lib/utils/text_utility */
/* eslint-disable no-new */

((global) => {
  describe('Dashboard', () => {
    const fixtureTemplate = 'dashboard.html';

    function todosCountText() {
      const countContainer = document.querySelector('.js-todos-count');

      return countContainer !== null ? countContainer.textContent : '';
    }

    function triggerToggle(newCount) {
      const event = new CustomEvent('todo:toggle', {
        detail: {
          count: newCount,
        },
      });
      document.dispatchEvent(event);
    }

    fixture.preload(fixtureTemplate);
    beforeEach(() => {
      fixture.load(fixtureTemplate);
      new global.Sidebar();
    });

    it('should update todos-count after receiving the todo:toggle event', () => {
      triggerToggle(5);
      expect(todosCountText()).toEqual('5');
    });

    it('should display todos-count with delimiter', () => {
      triggerToggle(1000);
      expect(todosCountText()).toEqual('1,000');

      triggerToggle(1000000);
      expect(todosCountText()).toEqual('1,000,000');
    });
  });
})(window.gl);
