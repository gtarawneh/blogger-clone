<%@ Page Language="C#" MasterPageFile="~/Dashboard/MasterPage.master" Title="Delete Post" %>

<%@ Import Namespace="System.Data.OleDb" %>

<script runat="server">
    
    protected void Page_Load()
    {
        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand();

        Com.Connection = Con;

        OleDbDataReader R;

        Com.CommandText = "select * from posts where postid=" + Request.Params[0];

        R = Com.ExecuteReader();

        R.Read();

        DeletePostPreview.InnerHtml = (string)R["PostBody"];

        Session["Section"] = "Delete Post";

        Session["Section-Title"] = "Delete '" + (string)R["PostTitle"] + "' ?";

        R.Close();

        Com.CommandText = "select * from settings where id=1;";

        R = Com.ExecuteReader();

        R.Read();

        DeletePostPreview.Style.Value = (string)R["Content"] + "padding: 15;";

        R.Close();

        
    }

    protected void Button1_Click(object sender, EventArgs e)
    {
        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand();

        Com.Connection = Con;

        Com.CommandText = "delete from posts where postid=" + Request.Params[0];

        Com.ExecuteNonQuery();

        Application["DataReloaded"] = null;

        Session["MsgText"] = "Your post has been deleted!";

        Session["RedirectURL"] = "posts.aspx";

        Session["MsgButton"] = "Proceed";

        Response.Redirect("message.aspx");


    }

    protected void Button2_Click(object sender, EventArgs e)
    {
        Response.Redirect("posts.aspx");

    }

</script>

<asp:Content runat="server" ContentPlaceHolderID="ContentPlaceHolder1">
    <div>
        <table id="Dashboard" style ="width:900px;">
            <tr>
                <td id="Header">
                    Confirm Delete
                </td>
            </tr>
            <tr>
                <td id="Content">
                     <div style="width: 100%; height: 280; overflow: scroll; border: solid #c8c8c8; border-width: 1">
            <div id="DeletePostPreview" runat="server">
            </div>
        </div> 
        <br />
        <span style ="float :right; text-align :right ;">
               Are you sure you want to delete the post shown above?<br />
        <br />
        <asp:Button ID="Button1" runat="server" Text="Delete" OnClick="Button1_Click" />
        <asp:Button ID="Button2" runat="server" Text="Cancel" OnClick="Button2_Click" />
        </span>
                </td>
            </tr>
        </table>
      
 
    </div>
</asp:Content>
