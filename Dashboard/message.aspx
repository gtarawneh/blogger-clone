<%@ Page Language="C#" MasterPageFile ="~/Dashboard/MasterPage.master"  %>

<script runat="server">
    
    protected void Page_Load()
    {
        Session["Section"] = "Message";

        Session["Section-Title"] = "Message";
        
        Label1.Text = (string)Session["MsgText"];

        Button1.Text = (string)Session["MsgButton"];
        
        
    }

    protected void Button1_Click(object sender, EventArgs e)
    {
        
        string URL = (string) Session["RedirectURL"];

        try
        {
            Response.Redirect(URL);
        }
        catch { };
    }

</script>

<asp:Content ContentPlaceHolderID ="ContentPlaceHolder1" runat ="server" >
            <center>
                <table id="MessageContainer">
                    <tr>
                        <td>
                            <asp:Label ID="Label1" runat="server" Text="Your post has been published successfully!" /><br />
                            <br />
                            <asp:Button ID="Button1" runat="server" Text="Proceed" OnClick="Button1_Click" />
                        </td>
                    </tr>
                </table>
            </center>

</asp:Content>