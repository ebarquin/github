(function() {
  this.NoteTemplate = (function() {
    function NoteTemplate() {
      this.initNoteTemplateDropdown();
    }

    NoteTemplate.prototype.initNoteTemplateDropdown = function() {
      return $('.js-note-template-dropdown').each(function() {
        var $dropdown, selected;
        $dropdown = $(this);
        selected = $dropdown.data('selected');
        return $dropdown.glDropdown({
          data: function(term, callback) {
            return $.ajax({
              url: $dropdown.data('refs-url'),
              data: {
                ref: $dropdown.data('ref')
              }
            }).done(function(refs) {
              return callback(refs);
            });
          },
          selectable: true,
          filterable: true,
          filterByText: true,
          fieldName: 'ref',
          renderRow: function(ref) {
            var link;
            link = $('<a />').attr('href', '#').addClass(ref === selected ? 'is-active' : '').text(ref).attr('data-ref', escape(ref));
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
