// work-around turbo links to trigger ready function stuff on every page.

var ready;
ready = function() {

    $("#checkFileSelectedCount").html('0');

    $("#checkAllFiles").click(function () {
        $(".checkFileGroup").prop('checked', $(this).prop('checked'));
        $("#checkFileSelectedCount").html($('.checkFile:checked').size());
    });

    $(".checkFileGroup").change(function () {
        $("#checkFileSelectedCount").html($('.checkFile:checked').size());
    });

    $('#term-supports').tooltip();

    $("#agreement").modal();

    $('#cancel-button').click(function () {
        window.location.href="/";
    });

    $('#dropdown-login').click(function(event)
    {
        if (event.stopPropagation){
            event.stopPropagation();
        }
        else if(window.event){
            window.event.cancelBubble=true;
        }
    });

}

function setDepositor(email, name){
    $('#depositor_email').val(email);
    $('#depositor_name').val(name);
}

$(document).ready(ready);
$(document).on('page:load', ready);