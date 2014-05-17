<%@ Page Language="C#" MasterPageFile="~/Dashboard/MasterPage.master" Title="Blog Settings"
    ValidateRequest="false" %>

<%@ Import Namespace="System.Data.OleDb" %>

<script runat="server">
   
    protected void Page_Load()
    {
        Session["Section"] = "Blog Settings";

        Session["Section-Title"] = "Blog Settings";

        if (!Page.IsPostBack)
        {

            TextBox1.Text = (string) Application ["Setting1"] ;
            
        }



    }

    protected void Button1_Click(object sender, EventArgs e)
    {
        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand();

        Com.Connection = Con;

        string EditorCSS = TextBox1.Text;

        EditorCSS = EditorCSS.Replace("'", "' + chr(39) + '");

        Com.CommandText = "update settings set content ='" + EditorCSS + "' where id=1";

        Com.ExecuteNonQuery();

        Session["MsgText"] = "Your settings were saved successfully!";

        Session["RedirectURL"] = "posts.aspx";

        Session["MsgButton"] = "Proceed";

        Application["SettingsReloaded"] = null;

        Response.Redirect("message.aspx");

        

    }
    protected void Button2_Click(object sender, EventArgs e)
    {
        Response.Redirect("posts.aspx");
    }

</script>

<asp:Content ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    Editor CSS:&nbsp;<br />
    <br />
    <asp:TextBox ID="TextBox1" Text="" runat="server" TextMode="MultiLine" Rows="10"
        Height="239px" Width="306px" />
    &nbsp;<br />
    <br />
    <br />
    <asp:Button ID="Button1" Text="Save" runat="server" OnClick="Button1_Click" />
    <asp:Button ID="Button2" Text="Cancel" runat="server" OnClick="Button2_Click" />
</asp:Content>
