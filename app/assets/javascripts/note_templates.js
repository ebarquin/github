(function() {
  this.NoteTemplate = (function() {
    function NoteTemplate() {
      this.initNoteTemplateDropdown();
    }

    NoteTemplate.prototype.initNoteTemplateDropdown = function() {
      return $('.js-note-template-btn').each(function() {
        console.log("Test51");
        var $dropdown;
        $dropdown = $(this);
        return $dropdown.glDropdown({
          data: function(term, callback) {
            return $.ajax({
              url: $dropdown.data('note-templates-url'),
              data: {
                note_template: $dropdown.data('note-template')
              },
              dataType: "json"
            }).done(function(templates) {
              return callback(templates);
            });
          },
          selectable: false,
          filterable: true,
          filterByText: true,
          renderRow: function(template) {
            return _.template('<li><a href="#" class="dropdown-menu-item-with-description"><span class="dropdown-menu-item-header"><%- title %></span><span class="dropdown-menu-item-body"><%- note %></span></a></li>')({ title: template.title, note: template.note });
          },
          id: function(obj, $el) {
            return $el.attr('data-note-template');
          },
          toggleLabel: function(obj, $el) {
            return $el.text().trim();
          },
          clicked: function(e) {
            e.preventDefault();
            return $dropdown.closest('form').val();
          }
        });
      });
    };

    return NoteTemplate;

  })();

}).call(this);
