$(function(){
  var holder = document.getElementById('holder');
  holder.ondragover = function () {
    return false;
  };
  holder.ondragleave = holder.ondragend = function () {
    return false;
  };
  holder.ondrop = function (e) {
    e.preventDefault();
    var file = e.dataTransfer.files[0];
    var file_path = file.path.toString();

    var fs = require('fs');
    var file_content = fs.readFileSync(file_path,{ encoding: 'utf8' });
    var file_lines = file_content.split(" ","<br>")

    var parsed_content = parseData(file_content)
    var html_content = certinfoString(parsed_content)

    $("#info > p").replaceWith(html_content);
    e.target.value = file.path;
    console.log('File you dragged here is', file.path);
    return false;
  };


  function  parseData(content)
  {
     //parse data
     var cert_info_array = [];

     var special_char = String.fromCharCode(9)
     var space_char = String.fromCharCode(32)
     content = content.replace(space_char , "")
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
                cert_info = new Object()
                cert_info.user_name = line.replace(/\s/g,"")
                break;
              case 1:
                cert_info.password = line.replace(/\s/g,"")
                break;
              case 2:
                cert_info.bundle_id = line.replace(/\s/g,"")
                cert_info.name = line.replace(".","")
                cert_info_array.push(cert_info)
                break;

              default:

            }
            index ++ ;
         }

     })

     return cert_info_array;
  }


  function certinfoString(cert_info_array)
  {
    var content = ""
    cert_info_array.forEach(function(cert_info,index){
      var cert_content = ""

      cert_content = cert_content + cert_info.user_name + "<br>"
      cert_content = cert_content + cert_info.password + "<br>"
      cert_content = cert_content + cert_info.bundle_id + "<br><br>"

      var certName = "cert"
      cert_content = "<div class='" + certName + "'>" + cert_content + "</div>"
      content = content + cert_content
    })
    return  content.length > 0 ? "<div class='certs'>"+ content +"</div>" : ""
  }

  function stopStep()
  {
   cert_info_array = []
   step_index  = 0
   is_parsed = false
   cert_index = 0;
  }


  $("#generate_cert").click(function(e){
      e.preventDefault();

      var exec = require('child_process').exec;
      var child;
      var command = "cert -u jobkai1853@163.com"

      child = exec(command,
      function (error, stdout, stderr) {
        console.log('stdout: ' + stdout);
        console.log('stderr: ' + stderr);
        if(stdout)
        {
          $("#stdout > pre").text(stdout)
        }

        if(stderr)
        {
          $("#stderr > pre").text(stderr)
        }
      });
  })
})
