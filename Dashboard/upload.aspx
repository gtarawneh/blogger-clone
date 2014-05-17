<%@ Page Language="C#" %>

<%@ Import Namespace="System.Drawing.Imaging" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<script runat="server">
    
    string physical_image_file = "";

    string physical_thumbnail_file = "";

    string virtual_image_file = "";

    string virtual_thumbnail_file = "";

    string img_style = "";

    string div_style = "";

    protected void Button1_Click(object sender, EventArgs e)
    {
        if (FileUpload1.HasFile)
        {

            System.Drawing.Image x = System.Drawing.Image.FromStream(FileUpload1.FileContent);

            System.Drawing.Image.GetThumbnailImageAbort dummyCallBack = new System.Drawing.Image.GetThumbnailImageAbort(ThumbnailCallback);
            
            

            int target_width = 200;

            if (RadioButtonList2.SelectedItem.Text == "Small") target_width = 200;
            if (RadioButtonList2.SelectedItem.Text == "Medium") target_width = 250;
            if (RadioButtonList2.SelectedItem.Text == "Large") target_width = 300;
            if (RadioButtonList2.SelectedItem.Text == "Full Size") target_width = x.Width ;


            double  scaling_factor = (double) x.Width / target_width;

            int thumb_width = target_width;

            int thumb_height =(int)(  (double) x.Height / scaling_factor);

            x.RotateFlip(System.Drawing.RotateFlipType.Rotate180FlipNone);

            x.RotateFlip(System.Drawing.RotateFlipType.Rotate180FlipNone);

            System.Drawing.Image y = x.GetThumbnailImage(thumb_width, thumb_height, dummyCallBack, IntPtr.Zero);

            string nam = FileUpload1.FileName.Substring(0, FileUpload1.FileName.LastIndexOf("."));

            string ext = FileUpload1.FileName.Substring(FileUpload1.FileName.LastIndexOf("."));

            string root_path = "http://" + Request.Url.Authority + Request.ApplicationPath;

            if (ext.ToLower() == ".jpg")
            {
                // Save as JPG

                physical_image_file = Server.MapPath("~/Images/") + FileUpload1.FileName;

                physical_thumbnail_file = Server.MapPath("~/Thumbnails/") + FileUpload1.FileName;
                
                x.Save(physical_image_file,ImageFormat.Jpeg );

                y.Save(physical_thumbnail_file,ImageFormat.Jpeg );

                virtual_image_file = root_path + "/Images/" + FileUpload1.FileName;

                virtual_thumbnail_file = root_path + "/Thumbnails/" + FileUpload1.FileName;
                
            }
            else
            {
                // Save as PNG

                physical_image_file = Server.MapPath("~/Images/") + nam + ".png";

                physical_thumbnail_file = Server.MapPath("~/Thumbnails/") + nam + ".png";

                x.Save(physical_image_file, ImageFormat.Png);

                y.Save(physical_thumbnail_file, ImageFormat.Png );

                virtual_image_file = root_path + "/Images/" + nam + ".png";

                virtual_thumbnail_file = root_path + "/Thumbnails/" + nam + ".png";
            }

            FileUpload1.Visible = false;

            Preview.InnerHtml = "<img src=\"" + virtual_thumbnail_file.ToLower () + "\"/>";
            
            if (RadioButtonList1.SelectedItem.Text  == "Left") img_style +="float: left; margin-right: 6px; ";
            if (RadioButtonList1.SelectedItem.Text == "Right") img_style += "float: right; margin-left: 6px; ";
            if (RadioButtonList1.SelectedItem.Text  == "Center") div_style += "text-align: center; margin-right: 6px ";

            if (RadioButtonList3.SelectedItem.Text == "None") img_style += "clear: both; ";
            if (RadioButtonList3.SelectedItem.Text == "on Left") img_style += "clear: right; ";
            if (RadioButtonList3.SelectedItem.Text == "on Right") img_style += "clear: left; ";
            if (RadioButtonList3.SelectedItem.Text == "on Both Sides") img_style += "clear: none; ";
            

            Div1.Visible = false;

            Div2.Visible = true;
        }

    }

    public bool ThumbnailCallback()
    {
        return false;
    }
    
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Upload Images</title>
    <link type="Text/css" href="MyStyles.css" rel="Stylesheet" />
    <style type="text/css">

    #span1
    {
        font-size: 11px;
    }

    input[type="button"]
    {
        width:100px;
        height : 25px;
        font-size :11px;
        vertical-align :top;
    }
        
    </style>

    <script type="text/javascript">
    
    function addpicture()
    {
        
        
        var editor;
        
        var p = window.opener ;

        if (document.all)
        {
           // textbox2= window.opener.all.xx.childNodes[0];
        }
        else
        {
           //
        }
        
        editor= p.document.getElementById('EditorBody');

        var thumb_src = '<%Response.Write(virtual_thumbnail_file.ToLower ()); %>';

        var img_src = '<%Response.Write(virtual_image_file.ToLower ()); %>';
        
        var img_style = '<%Response.Write(img_style.ToLower ()); %>';
        
        var div_style = '<%Response.Write(div_style.ToLower ()); %>';

        editor.contentDocument.body.innerHTML += '<div style="' + div_style + '"><a href="' + img_src + '"><img style="' + img_style + '" src="' + thumb_src + '"/></a></div><br/>';

        window.close ();

        
    }
    
    </script>

</head>
<body class="nicebody" style="font-size: 11px; padding: 10px">
    <form id="form1" runat="server">
        <div id="Div1" runat="server">
            <span class="title" style="font-size: 20px; margin-bottom: 15px; display: block;">Choose
                an image from your computer</span> <span id="span1">Image File:
                    <asp:FileUpload ID="FileUpload1" runat="server" /></span>
            <br />
            <br />
            <br />
            <table style="vertical-align: top;">
                <tr style="vertical-align: top;">
                    <td style="width: 200px;">
                        <b>Image Alignment:</b>
                        <asp:RadioButtonList ID="RadioButtonList1" runat="server">
                         <asp:ListItem Selected ="true" >None</asp:ListItem>
                            <asp:ListItem>Left</asp:ListItem>
                            <asp:ListItem>Center</asp:ListItem>
                            <asp:ListItem>Right</asp:ListItem>
                           
                        </asp:RadioButtonList>
                    </td>
                    <td style="width: 200px;">
                        <b>Thumbnail Size:</b>
                        <asp:RadioButtonList ID="RadioButtonList2" runat="server">
                            <asp:ListItem Selected ="true" >Small</asp:ListItem>
                            <asp:ListItem>Medium</asp:ListItem>
                            <asp:ListItem>Large</asp:ListItem>
                            <asp:ListItem>Full Size</asp:ListItem>
                        </asp:RadioButtonList>
                    </td>
                    <td>
                    <b>Allow Items:</b>
                       <asp:RadioButtonList ID="RadioButtonList3" runat="server">
                             <asp:ListItem Selected ="true" >None</asp:ListItem>
                            <asp:ListItem>on Left</asp:ListItem>
                            <asp:ListItem>on Right</asp:ListItem>
                            <asp:ListItem>on Both Sides</asp:ListItem>
                           
                        </asp:RadioButtonList>
                    </td>
                </tr>
                <tr>
                    <td colspan="2">
                        <br />
                        <asp:Button ID="Button1" Text="Upload" runat="server" OnClick="Button1_Click" />
                    </td>
                </tr>
            </table>
        </div>
        <div id="Div2" runat="server" visible="false">
       
        
        <span class="title" style="font-size: 20px; margin-bottom: 15px; display: block;">Image
                Uploaded Successfully!</span>
                
                Preview:<br /><br />
                
          <table style ="width:100%; height : 90%">
        
        <tr>
        <td style ="vertical-align :middle ">
        
       
            <div id="Preview" runat="server">
            </div>
        </td>
        </tr>

        </table>
    <br />
            <input type="Button" value="Ok" onclick="addpicture();" />
              
        </div>
    </form>
</body>
</html>
