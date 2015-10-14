 var cert_info_array = []  
 var rootPath = "" 
 var is_parsed = false
 var step_index = 0
 var cert_index = 0
 var step_count = 15.0




  function isParsed()
 {
   return is_parsed
 }

 function certInfoArray()
 {
   return cert_info_array
 }

 function certinfoString()
 {
   var content = ""
   cert_info_array.forEach(function(cert_info,index){
     var cert_content = ""

     cert_content = cert_content + cert_info.user_name + "\n"
     cert_content = cert_content + cert_info.password + "\n"
     cert_content = cert_content + cert_info.bundle_id + "\n\n"

     var certName = "cert"
     cert_content = "<div class='" + certName + "'>" + cert_content + "</div>" 
     content = content + cert_content
   })
   return  content.length > 0 ? "<div class='certs'>"+ content +"</div>" : ""
 }

 function stopStep()
 {


  cert_info_array = null
  step_index  = 0
  is_parsed = false

 }

function  parseData(content)
{
   //parse data 
  
  
   var special_char = String.fromCharCode(9)
   content = content.replace(" " , "")
   content = content.replace("\r","")
   content = content.replace("\t","")
   content = content.replace(special_char,"")
   var lines = content.split("\n")

   var cert_info = new Object()
   var index = 0
   lines.forEach(function(line){

       if(line != "")
       {
          switch (index%3) {
            case 0:
              cert_info.user_name = line
              break;
            case 1:
              cert_info.password = line
              break;
            case 2:
              cert_info.bundle_id = line
              cert_info.name = line.match(/\b\w?\d+\b/)[0]
              cert_info_array.push(cert_info)
              break;
            
            default:
              
          }
          index ++ ; 
       }

   })
   
   is_parsed = true

   //connect()

   chrome.tabs.query({currentWindow: true, active: true}, function (tab) {
      var tabUrl = encodeURIComponent(tab.url);
      var tabTitle = encodeURIComponent(tab.title);
      chrome.tabs.update(tab.id, {url: "https://developer.apple.com"});
   }) 
}

function sendMessage(message)
{
   chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
     chrome.tabs.sendMessage(tabs[0].id, message , function(response) {
       //console.log(response.farewell);
     });
   });
}

function nextStepper()
{

   //start stepper 
   cert_index = Math.floor(step_index / step_count)
   switch (step_index%step_count) {
      case 0:
          //fill user name and password
        sendMessage({
          "#accountname": cert_info_array[cert_index].user_name,
          "#accountpassword": cert_info_array[cert_index].password,
          "step": "login"
        }) 
         break;
    case 1:
      //jump to create cert page
      chrome.tabs.query({currentWindow: true, active: true}, function (tab) {
            var tabUrl = encodeURIComponent(tab.url);
            var tabTitle = encodeURIComponent(tab.title);
            chrome.tabs.update(tab.id, {url: "https://developer.apple.com/account/ios/certificate/certificateCreate.action"});
         }) 

      break;
    case 2:
      //choose cert type 
      var message = {"step": "choose_cert_type" }
     sendMessage(message)

      break;

    case 3:
       //continue request
      var message = {"step": "continue_cert_request" }
         sendMessage(message)

      break;
     case 4: 
       //download cert
       var message = {"step": "download_cert" }
         sendMessage(message)
      break;
     case 5:
          //jump to create bundle id url
         chrome.tabs.query({currentWindow: true, active: true}, function (tab) {
            var tabUrl = encodeURIComponent(tab.url);
            var tabTitle = encodeURIComponent(tab.title);
            chrome.tabs.update(tab.id, {url: "https://developer.apple.com/account/ios/identifiers/bundle/bundleCreate.action"});
         }) 
         break;
      case 6:
           //fill bundle id content
          sendMessage({
            "input[name='appIdName']": cert_info_array[0].name,
            "input[name='explicitIdentifier']": cert_info_array[0].bundle_id,
            "step": "fill_app_id"
          }) 
       break;
       case 7:
           var message = {"step": "submit_app_id"}
           sendMessage(message)

         break;
       case 8:
         //jump to create provisioning profile url
         chrome.tabs.query({currentWindow: true, active: true}, function (tab) {
            var tabUrl = encodeURIComponent(tab.url);
            var tabTitle = encodeURIComponent(tab.title);
            chrome.tabs.update(tab.id, {url: "https://developer.apple.com/account/ios/profile/profileCreate.action"});
         }) 

       break;
       case 9:
         //choose profile type
         sendMessage({
         "step": "choose_profile_type"
       })

       break;
       case 10:
          var message = {
           "step": "choose_profile_app_id",
           "select[name='appIdId']": "$(\"option:contains('"+ cert_info_array[cert_index].bundle_id +"')\").val()"
          }
          sendMessage(message) 

         break;
       case 11:
         var message = {"step": "choose_profile_cert" }
         sendMessage(message)

         break;
       case 12:
         var message = {"step": "fill_profile_name",
                        "input[name='provisioningProfileName']" : cert_info_array[cert_index].name
       }
         sendMessage(message)
         break;
       case 13:
         var message = {"step": "download_profile"}
         sendMessage(message)

         break;
       case 14:
         sendMessage({
         "step": "logout",
         "name": cert_info_array[cert_index].name
       })


        chrome.runtime.sendMessage({
         "step": "logout",
         "name": cert_info_array[cert_index].name
       });

       break;
     
     default:
       
   }

  step_index++
  if(Math.floor(step_index / step_count)>=cert_info_array.length)
  {
  stopStep()
  }

}


//listen
chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
  
    
  if(tab.url == 'https://developer.apple.com/')
  {
    var message = {"step": "enter_login_page"}
    chrome.tabs.sendMessage(tabId, message , function(response) {
       //console.log(response.farewell);
    });
  }
      
});
  
