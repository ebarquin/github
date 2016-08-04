(function() {
  this.NoteTemplate = (function() {
    function NoteTemplate() {
      $(document).on('click', '.js-note-template-btn', function(e) {
        return $(e.currentTarget).initNoteTemplateDropdown();
    }

    NoteTemplate.prototype.initNoteTemplateDropdown = function() {
      return $('.js-note-template-btn').each(function() {
        var $dropdown;
        $dropdown = $(this);
        return $dropdown.glDropdown({
          data: function(term, callback) {
            return $.ajax({
              url: $dropdown.data('note-templates-url'),
              data: {
                ref: $dropdown.data('note-template')
              }
            }).done(function(refs) {
              return callback(refs);
            });
          },
          selectable: false,
          filterable: true,
          filterByText: true,
          renderRow: function(template) {
            var link;
            link = $('<a />').attr('href', '#').text(template).attr('data-template', escape(template));
            return $('<li />').append(link);
          },
          id: function(obj, $el) {
            return $el.attr('data-ref');
          },
          toggleLabel: function(obj, $el) {
            return $el.text().trim();
          },
          clicked: function(e) {
            return $dropdown.closest('form').submit();
          }
        });
      });
    };

    return NoteTemplate;

  })();

}).call(this);
