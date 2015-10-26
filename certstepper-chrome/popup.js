$("document").ready(function(){
  
  $("#certinfo").on('change keyup paste', function(event) {
    this.style.height = "1px";
    this.style.height = (25+this.scrollHeight)+"px";
  }).change();

  var bgPage = chrome.extension.getBackgroundPage()
  if(bgPage.certinfoString().length > 0)
  {
    $("#certinfo").replaceWith(bgPage.certinfoString())
    $(".cert").removeClass("highlight").eq(bgPage.cert_index).addClass("highlight")
  }

  if(bgPage.rootPath)
  {
    $("#root_path").val(bgPage.rootPath)
  }

  if($(".cert").val())
  {
    $("#start").text("next")
  }

  $("#root_path").on('change keyup paste',function(event){
      var rootPath = $("#root_path").val()
      bgPage.rootPath = rootPath
  })


  $("#start").click(function(){
    if(bgPage.isParsed())
    {
      bgPage.nextStepper()
      $(".cert").removeClass("highlight").eq(bgPage.cert_index).addClass("highlight")
      if(bgPage.step_index==0)
      {
         $("#start").text("start") 
         $("#certinfo").val("")
      }
    }
    else
    {
      
       var content = $("#certinfo").val()
       if(content.length > 0)
       {
          bgPage.parseData(content);
          $("#start").text("next")
          $("#certinfo").replaceWith(bgPage.certinfoString())
          $(".cert").removeClass("highlight").eq(bgPage.cert_index).addClass("highlight")

       }
    }
  });

  $("#stop").click(function(){
    $("#certinfo").val("")
    $("#start").text("start") 
      bgPage.stopStep();
  })


  chrome.runtime.onMessage.addListener(
  function(request, sender, sendResponse) {
    if(request["step"] == "logout") 
      {
          var message = {"profile_name": request["name"],
             "start_path": bgPage.rootPath};

        chrome.runtime.sendNativeMessage('com.kaich.certstepper',
        message,
        function(response) {
          if (chrome.runtime.lastError) {
              console.log("ERROR: " + chrome.runtime.lastError.message);
          } else {
              console.log("Messaging host sais: ", response);
          }
        });
      }
  })


})
