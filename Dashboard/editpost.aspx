<%@ Page Language="C#" ValidateRequest="false" MasterPageFile="~/Dashboard/MasterPage.master"
    Title="Post Editor" %>

<%@ Import Namespace="System.Data.OleDb" %>

<script runat="server">
    
    string EditorCSS;

    string isDraft = "0";

    string isBlogPage = "0";

    string disallowComments = "0";

    protected void Page_Load()
    {
        Session["Section"] = "Post Editor";

        if (!Page.IsPostBack)
        {
            OleDbConnection Con = (OleDbConnection)Application["Con"];

            OleDbCommand Com = new OleDbCommand();

            Com.Connection = Con;

            OleDbDataReader R;

            if (Request.Params["id"] == "create" || Request.Params["id"] == null)
            {
                // New Post

                Session["Section-Title"] = "Create New Post";

            }
            else
            {
                // Edit existing post or comment

                if (Request.Params["type"] == null)
                {
                    // Edit Post

                    Com.CommandText = "select * from Posts where PostID=" + Request.Params["id"];

                    R = Com.ExecuteReader();

                    R.Read();

                    TextBox1.Text = (string)R["PostTitle"];

                    TextBox2.Text = (string)R["PostBody"];

                    isDraft = (bool) R["PostDraft"]  ? "1" : "0";

                    isBlogPage = (bool) R["PostBlogPage"]  ? "1" : "0";

                    disallowComments = (bool)R["PostAllowComments"] ? "0" : "1";

                    Session["Section-Title"] = "Editing '" + (string)R["PostTitle"] + "'";

                    R.Close();
                }
                else
                {
                    // Edit Comment

                    Com.CommandText = "select * from Comments where ComID=" + Request.Params["id"];

                    R = Com.ExecuteReader();

                    R.Read();

                    TextBox1.Text = "Comment";

                    TextBox1.Enabled = false;

                    TextBox2.Text = (string)R["ComBody"];

                    Session["Section-Title"] = "Editing Comment";

                    R.Close();
                }


            }

            Com.CommandText = "select * from Settings where ID=1";

            R = Com.ExecuteReader();

            R.Read();

            EditorCSS = (string)R["Content"];

            EditorCSS = EditorCSS.Replace("\"", "\" + String.fromCharCode(34) + \"");

            EditorCSS = EditorCSS.Replace("\r\n", "");

            R.Close();


        }
    }

    protected void Button1_Click(object sender, EventArgs e)
    {
        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand();

        string PostBody = TextBox2.Text;

        string PostTitle = TextBox1.Text;

        string draft = (CheckBox1.Checked) ? "1" : "0";

        string blog_page = (CheckBox2.Checked) ? "1" : "0";

        string allow_comments = (CheckBox3.Checked) ? "0" : "1";
         
        PostBody = PostBody.Replace("'", "' + chr(39) + '");

        PostTitle = PostTitle.Replace("'", "' + chr(39) + '");

        Com.Connection = Con;

        bool ispost = (Request.Params["type"] == null);

        bool newpost = (Request.Params["id"] == null || Request.Params["id"] == "create");

        // Creating / Updating post's database record     

        if (ispost && newpost)
        {
            DateTime dt = DateTime.Now;

            if ((bool)(Application["IsRemote"]) == true) dt = dt.AddHours(Convert.ToDouble(Application["Setting19"]));

            string post_date = dt.ToString("dd/MMM/yyyy hh:mm:ss tt");

            Com.CommandText = "insert into Posts (PostTitle, PostBody, PostDate, PostUserID, PostDraft, PostBlogPage, PostAllowComments, PostVirtualFile) values ('" + PostTitle + "', '" + PostBody + "','" + post_date + "',1," + draft + "," + blog_page +"," + allow_comments  +",'')";

            Com.ExecuteNonQuery();

            Com.CommandText = "select PostID from Posts where PostTitle='" + PostTitle + "' and PostBody='" + PostBody + "'";

            string post_id = Convert.ToString(Com.ExecuteScalar());

            string virtual_file = CreateVirtualFileName(PostTitle.Replace ("' + chr(39) + '","'"), post_id, false);

            Com.CommandText = "select count(*) as C from Posts where PostID<>" + post_id + " and PostVirtualFile='" + virtual_file + "'";

            int c = (int)Com.ExecuteScalar();

            if (c > 0) virtual_file = CreateVirtualFileName(PostTitle.Replace("' + chr(39) + '", "'"), post_id, true);

            Com.CommandText = "update Posts set PostVirtualFile='" + virtual_file + "' where PostID=" + post_id;

            Com.ExecuteNonQuery();

        }
        else if (ispost)
        {
            string post_id = (string)Request.Params["id"];

            string virtual_file = CreateVirtualFileName(PostTitle.Replace("' + chr(39) + '", "'"), post_id, false);

            Com.CommandText = "select count(*) as C from Posts where PostID<>" + post_id + " and PostVirtualFile='" + virtual_file + "'";

            int c = (int)Com.ExecuteScalar();

            if (c > 0) virtual_file = CreateVirtualFileName(PostTitle.Replace("' + chr(39) + '", "'"), post_id, true);

            Com.CommandText = "update Posts set PostBody='" + PostBody + "', PostTitle='" + PostTitle + "', PostVirtualFile='" + virtual_file + "', PostDraft=" + draft + ", PostBlogPage=" + blog_page + ", PostAllowComments = " + allow_comments + " where PostID=" + post_id;

            Com.ExecuteNonQuery();
        }
        else
        {
            // Comment

            string com_id = (string)Request.Params["id"];

            Com.CommandText = "update Comments set ComBody='" + PostBody + "' where ComID=" + com_id;

            Com.ExecuteNonQuery();

        }

        Session["MsgText"] = "Your post has been published successfully!";

        Session["RedirectURL"] = "posts.aspx";

        if (Session["CancelPage"] != null) Session["RedirectURL"] = Session["CancelPage"];

        Session["MsgButton"] = "Proceed";

        Application["DataReloaded"] = null;

        Response.Redirect("message.aspx");

    }

    protected void Button2_Click(object sender, EventArgs e)
    {
        string return_page = "posts.aspx";

        if (Session["CancelPage"] != null) return_page = (string)Session["CancelPage"];

        Response.Redirect(return_page);

    }

    protected string CreateVirtualFileName(string title, string id, bool merge)
    {
        string virtual_filename = title.ToLower();

        virtual_filename = virtual_filename.Replace(" ", "-");

        for (int i = 0; i < virtual_filename.Length; i++)
        {
            char c = virtual_filename[i];

            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || (c == '-'))
            {
                // it's Ok =)
            }
            else
            {
                virtual_filename = virtual_filename.Remove(i, 1);
                i--;
            }
        }

        virtual_filename = virtual_filename.Replace("--", "");

        if (virtual_filename == "")
        {
            virtual_filename = "post" + id;
        }

        if (merge) virtual_filename += id;

        virtual_filename += ".htm";

        return virtual_filename;
    }

</script>

<asp:Content runat="server" ContentPlaceHolderID="ContentPlaceHolder1">

    <script type="text/javascript">

    var ViewMode = 1;

    function PrepareEditor()
    {
        if (document.all)
        {
            frames.EditorBody.document.designMode = 'On';
        }
        else
        {
            document.getElementById("EditorBody").contentDocument.designMode ='on';
        }
    }
    
    function GetHTML()
    {


        var HTML; // = d.body.innerHTML;
        
        if (document.all)
        {
            // IE
            
            HTML = window.frames.item (0).document.body.innerHTML;
            
        }
        else
        {
            // FireFox
            
            var d = document.getElementById("EditorBody").contentDocument;
        
            HTML = d.body.innerHTML;
        }
        
        GetText2Ref().value = HTML;
    }
    
    function GetRich()
    {
        var EditorCSS = "<% Response.Write(EditorCSS); %>";
        
        if (document.all)
        {
            // IE
            
            window.frames.item (0).document.writeln ("<body style='" + EditorCSS + "'>");
            
            EditorBody.document.body.innerHTML = GetText2Ref().value;
        }
        else
        {
            // FireFox
            
            var d = document.getElementById("EditorBody").contentDocument;
        
            d.body.setAttribute ("style", EditorCSS);
            
            d.body.innerHTML = GetText2Ref().value;
           
         }            
    }
    
    function Page_Load()
    {
        PrepareEditor();
        
        LoadPostOptions();
        
        ChangePublishButton();
        
        document.all.btn1.unselectable = 'on';
        document.all.btn2.unselectable = 'on';
        document.all.btn3.unselectable = 'on';
        document.all.btn4.unselectable = 'on';
        document.all.btn5.unselectable = 'on';
        document.all.btn6.unselectable = 'on';
        document.all.btn7.unselectable = 'on';
        document.all.btn8.unselectable = 'on';
        document.all.btn9.unselectable = 'on';
        document.all.btn10.unselectable = 'on';
        document.all.btn11.unselectable = 'on';
        document.all.btn12.unselectable = 'on';
      
        
      //  document.getElementById ("btn12").unselectable = 'on';
        
    }
    
    function DoEditorCommand(C)
    {
        if (document.all)
        {
            // IE
            
            EditorBody.document.execCommand(C, false, null); 
        }
        else
        {
            // FireFox
            
            var d = document.getElementById("EditorBody").contentDocument;
            
            d.execCommand(C, false, null); 
 
        }
            
    }
    
    function change(vm)
    {
        
        if (vm==1)
        {
            document.all.html_button.style.background = "url(Graphics/edit_html_2.gif)";

            document.all.compose_button.style.background = "url(Graphics/compose_2.gif)";
            
            GetText2Ref().style.visibility='hidden';
            
            document.all.Editor.style.visibility='visible';
            
            GetRich();
        }
        else
        {
            document.all.html_button.style.background = "url(Graphics/edit_html_1.gif)";

            document.all.compose_button.style.background = "url(Graphics/compose_1.gif)";
          
            GetText2Ref().style.visibility='visible';
            
            document.all.Editor.style.visibility='hidden';
            
            GetHTML();
        }
        
        ViewMode = vm;
   }
   
   function btn_mouseover(b)
   {
        b.style.borderStyle='solid';
        
       b.style.borderTopColor = "white";
       
       b.style.borderLeftColor = "white";
       
       b.style.borderRightColor= "rgb(200,200,200)";
       
       b.style.borderBottomColor= "rgb(200,200,200)";
   
   }
   
   function btn_mouseout(b)
   {
        b.style.borderColor = '#f8fafb';
   }
   
   function btn_mousedown(b)
   {
       b.style.borderTopColor = "rgb(200,200,200)";
       
       b.style.borderLeftColor = "rgb(200,200,200)";
       
       b.style.borderRightColor= "white";
       
       b.style.borderBottomColor= "white";
   }
   
   function btn_mouseup(b)
   {

        btn_mouseover(b);
   }
   
   function GetText2Ref()
   {
        return document.getElementById ('<% Response.Write(TextBox2.ClientID); %>');
   }
   
   function special()
   {
        window_height = 375;
        
        window_width = 650;

        x = (screen.width - window_width) / 2;
        
        y = (screen.height - window_height) / 2;

        window1 = window.open ('upload.aspx','Hello','width=' + window_width  + ',height=' + window_height + ',left=' + x + ', top=' + y); 
   }
   
    function SubmitPreview()
    {

        if (ViewMode==1) GetHTML(); 

        var PreviewForm = document.getElementById ("pageform");

        document.getElementById ("field1").value =  document.getElementById ('<% Response.Write(TextBox1.ClientID); %>').value;

        document.getElementById ("field2").value = document.getElementById ('<% Response.Write(TextBox2.ClientID); %>').value;
        
        document.getElementById ("field3").value = "PreviewForm";

        PreviewForm.method = "POST";

        PreviewForm.action = "../default.aspx";

        PreviewForm.target = "_blank";

        PreviewForm.submit();

    }
    
    function LoadPostOptions()
    {
        var draft = <%Response.Write(isDraft); %>;    
    
        var blog_page = <%Response.Write (isBlogPage); %>
 
        var disallow_comments = <%Response.Write(disallowComments); %>
        
        var check1 = document.getElementById ('<% Response.Write(CheckBox1.ClientID); %>');
        var check2 = document.getElementById ('<% Response.Write(CheckBox2.ClientID); %>');
        var check3 = document.getElementById ('<% Response.Write(CheckBox3.ClientID); %>');
            
        if (draft == 1) check1.checked = true; else check1.checked = false;

        if (blog_page == 1) check2.checked = true; else check2.checked = false;

        if (disallow_comments == 1) check3.checked = true; else check3.checked = false;

    }
    
    function ChangePublishButton()
    {
        var check1 = document.getElementById ('<% Response.Write(CheckBox1.ClientID); %>');
        
        var BTN = document.getElementById ('SubmitBTN');

        if (check1.checked)
        {
            BTN.innerHTML = "Save";
            BTN.className = "SaveButton";
        }
        else
        {
            BTN.innerHTML = "Publish";
            BTN.className = "PublishButton";
        }
    }
    
   
        

    </script>

    <div>
        <div style="margin-left: 150px; margin-top: 10px;">
            <table style="border-collapse: collapse; position: relative; border: solid green;
                border-width: 0">
                <tr>
                    <td colspan="2">
                        <span style="float: left; vertical-align: bottom; font-size: 11px; position: relative;
                            top: 5px; margin-right: 8px;">Post Title : </span>
                        <asp:TextBox ID="TextBox1" runat="server" CssClass="InsideContainer" Style="width: 300px;
                            padding: 5; float: left; border: solid #b1bbc5; border-width: 1px"></asp:TextBox>
                        <div name="compose_button" id="compose_button" onclick="change(1);">
                        </div>
                        <div name="html_button" id="html_button" onclick="change(0);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td colspan="2">
                        <div id="test" style="width: 650; height: 350; background: #f8fafb; border: solid #b1bbc5;
                            border-width: 1;">
                            <center>
                            <div id="PostOptions" style ="position:relative; left : 120px; top:60px; visibility :hidden ;">
                            
                            
                            <table id="Dashboard" style ="width: 400px; height :200px; font-size:11px; z-index :1; position : absolute ;">
                            <tr><td id="Header">Post Options</td></tr>
                            <tr><td id="Content">
                            <asp:CheckBox ID ="CheckBox1" runat ="server" style="position: relative ; top: 4px; margin-right: 5px;" />Draft<br />
                            <hr />
                            <asp:CheckBox ID ="CheckBox2" runat ="server" style="position: relative ; top: 4px; margin-right: 5px;" />Blog Page<br />
                            <hr />
                            <asp:CheckBox ID ="CheckBox3" runat ="server" style="position: relative ; top: 4px; margin-right: 5px;" />Do not allow comments on this post<br />
                            <hr />
                            <input type="button" value ="Cancel" onclick ="document.getElementById('PostOptions').style.visibility='hidden';LoadPostOptions();"  style ="float :right ;" class ="MediumButton" />
                            <input type="button" value ="Ok"  onclick ="document.getElementById('PostOptions').style.visibility='hidden'; ChangePublishButton();" style ="float :right ; margin-right :10px;" class ="MediumButton" />
                            
                            </td></tr>
                            </table>
                            
                            
                               </div> <table>
                                    <tr>
                                        <td>
                                            <div id="xx" name="xx" style="position: relative; height: 0;">
                                                <asp:TextBox ID="TextBox2" Style="border: solid #b1bbc5; border-width: 1; visibility: hidden;
                                                    position: absolute; left: 0; top: 39; height: 294; width: 632;" runat="server"
                                                    TextMode="MultiLine"></asp:TextBox>
                                            </div>
                                            <div id="Editor" name="Editor">
                                                <div id="Toolbar">
                                                    <table style="padding: 0; border-collapse: collapse; width: 100%; height: 40">
                                                        <tr>
                                                            <td>
                                                                <div name="btn11" id="btn11" style="cursor: default; font-size: 11px; width: 82px;
                                                                    padding-left: 5px; padding-top: 5px; height: 20px; background-image: url('Graphics/arrow.gif');
                                                                    background-position: 75px center" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)">
                                                                    Font Family</div>
                                                                <div name="btn12" id="btn12" style="cursor: default; font-size: 11px; width: 70px;
                                                                    padding-top: 5px; padding-left: 5px; height: 20px; background-image: url('Graphics/arrow.gif');
                                                                    background-position: 62px center" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)">
                                                                    Font Size</div>
                                                                <!--
                                                                        <span style="font-family: Verdana; font-size: 11; float: left; position: relative;
                                                                            top: 7">Font : </span>
                                                                        <div style="float: left; width: 5px;">
                                                                            &nbsp</div>
                                                                        <select style="position: relative; float: left; font-family: Verdana; font-size: 11px;
                                                                            top: 4; width: 140;" name="fontname">
                                                                            <option onclick="alert(5);" value="Template Default">(Default)</option>
                                                                            <option value="Arial">Arial</option>
                                                                            <option value="Courier">Courier</option>
                                                                            <option value="Georgia">Georgia</option>
                                                                            <option value="Lucida Grande">Lucida Grande</option>
                                                                            <option value="Times New Roman">Times New Roman</option>
                                                                            <option value="Trebuchet">Trebuche</option>
                                                                            <option value="Verdana">Verdana</option>
                                                                            <option value="Webdings">Webdings</option>
                                                                        </select>
                                                                        <div style="float: left; width: 10px;">
                                                                            &nbsp</div>
                                                                        <select style="position: relative; float: left; font-family: Verdana; font-size: 11px;
                                                                            top: 4; width: 50;" name="fontname">
                                                                            <option value="Arial"></option>
                                                                            <option value="Arial">8</option>
                                                                            <option value="Courier">9</option>
                                                                            <option value="Verdana">10</option>
                                                                            <option value="Verdana">11</option>
                                                                            <option value="Verdana">12</option>
                                                                            <option value="Verdana">14</option>
                                                                            <option value="Verdana">16</option>
                                                                            <option value="Verdana">18</option>
                                                                            <option value="Verdana">20</option>
                                                                            <option value="Verdana">22</option>
                                                                        </select>
                                                                        <div style="float: left; width: 15px;">
                                                                            &nbsp</div>
                                                                            
                                                                            -->
                                                                <div name="btn1" id="btn1" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('Bold');" style="background-image: url('Graphics/bold.gif');">
                                                                </div>
                                                                <div name="btn2" id="btn2" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('Italic');" style="background-image: url('Graphics/italic.gif');">
                                                                </div>
                                                                <div name="btn3" id="btn3" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('Underline');" style="background-image: url('Graphics/underline.gif');">
                                                                </div>
                                                                <div name="btn4" id="btn4" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('justifyleft');" style="background-image: url('Graphics/left.gif');">
                                                                </div>
                                                                <div name="btn5" id="btn5" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('justifycenter');" style="background-image: url('Graphics/center.gif');">
                                                                </div>
                                                                <div name="btn6" id="btn6" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('justifyright');" style="background-image: url('Graphics/right.gif');">
                                                                </div>
                                                                <div name="btn7" id="btn7" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('justifyFull');" style="background-image: url('Graphics/justify.gif');">
                                                                </div>
                                                                <div name="btn8" id="btn8" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('InsertUnorderedList');" style="background-image: url('Graphics/blist.gif');">
                                                                </div>
                                                                <div name="btn9" id="btn9" class="ToolbarButton" onmouseout="btn_mouseout(this)"
                                                                    onmouseover="btn_mouseover(this)" onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)"
                                                                    onclick="DoEditorCommand('InsertOrderedList');" style="background-image: url('Graphics/nlist.gif');">
                                                                </div>
                                                                <div name="btn10" id="btn10" onmouseout="btn_mouseout(this)" onmouseover="btn_mouseover(this)"
                                                                    onmouseup="btn_mouseup(this)" onmousedown="btn_mousedown(this)" onclick="special();"
                                                                    class="ToolbarButton" style="background-image: url('Graphics/image.gif');">
                                                                </div>
                                                            </td>
                                                        </tr>
                                                    </table>
                                                </div>
                                                <div style="background-color: White;">
                                                    <iframe id="EditorBody" style="border: solid #b1bbc5; border-width: 1px;" frameborder="0"
                                                        onload="GetRich();"></iframe>
                                                       
                                                </div>
                                                
                                            </div>
                                        </td>
                                    </tr>
                                </table>
                            </center>
                        </div>
                    </td>
                </tr>
                <tr>
                    <td style="width: 350px; height: 50px;">
                        <div onmouseover="this.style.backgroundColor='white'" onmouseout="this.style.backgroundColor=''"
                            onclick="SubmitPreview();" class="PreviewButton" style ="float:left ;">
                            Preview</div>
                            <div class ="PostOptionsButton" onclick ="document.getElementById('PostOptions').style.visibility='visible';" onmouseover="this.style.backgroundColor='white'" onmouseout="this.style.backgroundColor=''" style ="float :left ; width : 80px; margin-left:10px;">Post Options</div>
                    </td>
                    <td style="text-align: right;">
                        <div onmouseover="this.style.backgroundColor='white'" onmouseout="this.style.backgroundColor=''"
                            style="float: right" class="CancelButton" onclick ="document.getElementById('<% Response.Write(CancelBTN.ClientID); %>').click();">
                            Cancel</div>
                        <div id="SubmitBTN" onmouseover="this.style.backgroundColor='white'" onmouseout="this.style.backgroundColor=''"
                            style="float: right; margin-right: 10px;" class="PublishButton" onclick="if (ViewMode==1) GetHTML(); document.getElementById('<% Response.Write(SubmitBTN.ClientID); %>').click();"
                            onclick="Button1_Click">
                            Publish</div>
                        <!-- Hidden Buttons -->
                        <asp:Button runat="server" ID="SubmitBTN" OnClick="Button1_Click" Style="display: none;" />
                        <asp:Button runat="server" ID="CancelBTN" OnClick="Button2_Click" Style="display: none;" />
                        <!-- /Hidden Buttons -->
                    </td>
                </tr>
            </table>
        </div>
        <br />
    </div>
</asp:Content>
