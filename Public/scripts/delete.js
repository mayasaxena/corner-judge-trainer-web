$(document).ready(function () {
    $(".x.button" ).click(function() {
        var matchID = $(this).val()
        if (confirm("Delete match " + matchID + "?")) {
            $.ajax({
               url: '/match/' + matchID,
               type: 'DELETE',
               success: function(response) {
                   location.reload();
               }
            });
        }
    });
});
