/* eslint-disable func-names, space-before-function-paren, one-var, no-var, one-var-declaration-per-line, no-undef, prefer-arrow-callback, camelcase, max-len, consistent-return, quotes, object-shorthand, comma-dangle, padded-blocks, max-len */
// Quick Submit behavior
//
// When a child field of a form with a `js-quick-submit` class receives a
// "Meta+Enter" (Mac) or "Ctrl+Enter" (Linux/Windows) key combination, the form
// is submitted.
//
/*= require extensions/jquery */

//
// ### Example Markup
//
//   <form action="/foo" class="js-quick-submit">
//     <input type="text" />
//     <textarea></textarea>
//     <input type="submit" value="Submit" />
//   </form>
//
(function() {
  var isMac, keyCodeIs;

  isMac = function() {
    return navigator.userAgent.match(/Macintosh/);
  };

  keyCodeIs = function(e, keyCode) {
    if ((e.originalEvent && e.originalEvent.repeat) || e.repeat) {
      return false;
    }
    return e.keyCode === keyCode;
  };

  $(document).on('keydown.quick_submit', '.js-quick-submit', function(e) {
    var $form, $submitButton, $altSubmitButton;
    // Enter
    if (!keyCodeIs(e, 13)) {
      return;
    }
    if (e.shiftKey || (e.metaKey && e.ctrlKey)) {
      return;
    }
    if (!(e.metaKey || e.ctrlKey)) {
      return;
    }
    $form = $(e.target).closest('form');
    $submitButton = $form.find('input[type=submit], button[type=submit]');
    if (e.altKey) {
      $submitButton = $submitButton.filter('[data-quick-submit-alt]');
      if ($submitButton.length === 0) {
        return;
      }
    }
    e.preventDefault();
    if ($submitButton.attr('disabled')) {
      return;
    }
     // Click button instead of submitting form, so that button name and value are sent along
    $submitButton.click();
  });

  // If the user tabs to a submit button on a `js-quick-submit` form, display a
  // tooltip to let them know they could've used the hotkey
  $(document).on('keyup.quick_submit', '.js-quick-submit input[type=submit], .js-quick-submit button[type=submit]', function(e) {
    var $this, title, quickSubmitAlt;
    // Tab
    if (!keyCodeIs(e, 9)) {
      return;
    }

    $this = $(this);

    quickSubmitAlt = $this.data('quick-submit-alt');

    if (isMac()) {
      if (quickSubmitAlt) {
        shortcut = "&#8997&#8984;&#9166;";
      }
      else {
        shortcut = "&#8984;&#9166;";
      }
    } else {
      if (quickSubmitAlt) {
        shortcut = "Ctrl-Alt-Enter";
      }
      else {
        shortcut = "Ctrl-Enter";
      }
    }

    title = "You can also press " + shortcut;

    return $this.tooltip({
      container: 'body',
      html: 'true',
      placement: 'auto top',
      title: title,
      trigger: 'manual'
    }).tooltip('show').one('blur', function() {
      return $this.tooltip('hide');
    });
  });

}).call(this);
