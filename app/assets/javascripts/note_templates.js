(function() {
  this.NoteTemplate = (function() {
    function NoteTemplate() {
      this.initNoteTemplateDropdown();
    }

    NoteTemplate.prototype.initNoteTemplateDropdown = function() {
      return $('.js-note-template-btn').each(function() {
        var $dropdown, $textarea;
        $dropdown = $(this);
        $textarea = $dropdown.parents(".md-area").find("textarea");
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
          selectable: true,
          filterable: true,
          filterByText: true,
          renderRow: function(template) {
            return _.template('<li><a href="#" class="dropdown-menu-item-with-description"><span class="dropdown-menu-item-header"><%- title %></span><span class="dropdown-menu-item-body"><%- note %></span></a></li>')({ title: template.title, note: template.note });
          },
          id: function(obj, $el) {
            return $el.attr('data-note-template');
          },
          clicked: function(selected, $el, e) {
            e.preventDefault();
            return window.gl.text.updateText($textarea, selected.note, false, false);
          }
        });
      });
    };

    return NoteTemplate;

  })();

}).call(this);
