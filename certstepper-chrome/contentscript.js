chrome.runtime.onMessage.addListener(
  function(request, sender, sendResponse) {

    
    //Your code below...
    for(var key in request)
    {
      $(key).focus()
      var value = request[key];
      if(value.includes('$'))
      {
         var final_value = eval(value)
         $(key).val(final_value)
      }
      else if(value.includes('('))
      {
         $(key).attr(value)
      }
      else
      {
        $(key).val(value)
      }
    }


    $(".validate:not([validated=true])").attr("validated",true)
    switch (request["step"]) {
      case 'enter_login_page':
        $("a:contains('Member Center')")[0].click()
        break;
      case 'login':
        $("#submitButton2").click()
        break;
      case 'enter_ios':
        $("#ios-apps").find("[href='/account/ios/certificate/certificateList.action']").click() 
        break;
      case 'choose_cert_type':
        $("#type-development").attr("checked","checked")
        setTimeout(function() {
          var continue_button = $("a:contains('Continue')"); 
          continue_button.removeClass("disabled")
          continue_button[0].click()
        }, 1000);
        break;
      case 'continue_cert_request':
        setTimeout(function() {
          var continue_button = $("a:contains('Continue')"); 
          continue_button.removeClass("disabled")
          continue_button[0].click()
        }, 1000);

        break;
      case 'download_cert':
        $("a:contains('Download')")[0].click()
        break;
      case 'fill_app_id':
        setTimeout(function() {
          var continue_button = $("a:contains('Continue')"); 
          continue_button.removeClass("disabled")
          continue_button[0].click()
        }, 1000);
        break;
      case 'submit_app_id':
        $("a:contains('Submit')")[0].click()
        break;
      case 'choose_profile_type':
        $("#type-development").attr("checked","checked")
        setTimeout(function() {
          var continue_button = $("a:contains('Continue')"); 
          continue_button.removeClass("disabled")
          continue_button[0].click()
        }, 1000);
        break;
      case 'choose_profile_app_id':
       
        setTimeout(function() {
          var continue_button = $("a:contains('Continue')"); 
          continue_button.removeClass("disabled")
          continue_button[0].click()
        }, 1000);
      break;
      case 'choose_profile_cert':
        var select_all = $("div.selectAll > input[type='checkbox']")
        var all_rows = $("div.rows input[name='certificates']")
        if(select_all)
        {
          select_all.attr("checked","checked")
          all_rows.attr("checked","checked")
        }
        setTimeout(function() {
          var continue_button = $("a:contains('Continue')"); 
          continue_button.removeClass("disabled")
          continue_button[0].click()
        }, 1000);
      break;
      case 'fill_profile_name':
        setTimeout(function() {
          var continue_button = $("a:contains('Generate')"); 
          continue_button.removeClass("disabled")
          continue_button[0].click()
        }, 1000);
      break;
      case 'download_profile':
        $("a:contains('Download')")[0].click()
      break;
      case 'logout':
        $("li.sign-out a.last-option")[0].click() 
        break;
      default:
        
    }
    
});
