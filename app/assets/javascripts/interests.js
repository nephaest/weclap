$(document).ready(function() {

  $(function() {
    $('.selectpicker.checkbox-diff').on('change', function(){
      var selected = $(this).find("option:selected").val();
      if (selected === 'on_vod'){
        $(".interest-js").removeClass('hidden')
        $(".interest-js:not(.streams)").addClass('hidden');
      }
      else if (selected === 'on_Theater'){
        $(".interest-js").removeClass('hidden')
        $(".interest-js:not(.theater)").addClass('hidden');
      }
      else if (selected === 'all'){
        $(".interest-js").removeClass('hidden')
      }
    });




    $('.selectpicker.sort-by').on('change', function(e){
      console.log(e.currentTarget.selectedIndex);
      $.ajax({
        type: "GET",
        data: {sort: e.currentTarget.selectedIndex},
        url: '/sort',
        success: function(data) {
          console.log('on passe dans le JS tout court');
        },
        error: function(jqXHR) {
          console.error(jqXHR.responseText);
        }
      });
    });

    $('.selectpicker.genres').on('changed.bs.select', function(){
      var selected =  $('.selectpicker.genres').select().val();
        if (selected == "All") {
          $(".interest-js").removeClass('hidden');
        }
        else {
          $(".interest-js").addClass('hidden');
          for (var i = 0; i < selected.length; i += 1) {
            $(".interest-js." + selected[i] + "").removeClass('hidden');
          }
        }
    });


  });
});

// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.





