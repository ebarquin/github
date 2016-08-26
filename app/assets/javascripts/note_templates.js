(function() {
  this.NoteTemplate = (function() {
    function NoteTemplate() {
      this.initNoteTemplateDropdown();
      console.log("Test");
    }

    NoteTemplate.prototype.initNoteTemplateDropdown = function() {
      console.log("Test2");
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
            var link;
            link = $('<a />').attr('href', '#').text(template.title).attr('data-template', escape(template.title));
            return $('<li />').append(link);
          },
          id: function(obj, $el) {
            return $el.attr('data-note-template');
          },
          toggleLabel: function(obj, $el) {
            return $el.text().trim();
          },
          clicked: function(e) {
            console.log("CLICKED");
            return $dropdown.closest('form').val();
          }
        });
      });
    };

    return NoteTemplate;

  })();

}).call(this);
