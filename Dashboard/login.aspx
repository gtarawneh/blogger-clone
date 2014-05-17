<%@ Page Language="C#" %>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title><% Response.Write((string)Application["Setting2"]); %> - Login</title>

    <script runat="server">
    
        protected void Button1_Click(object sender, EventArgs e)
        {
            if (TextBox2.Text == "PASSWORD_HERE") ' This is an awful way of authentication and is here just as a placeholder, replace with your own login implementation
            {

                Session["Logged"] = "True";

                Session["User"] = TextBox1.Text;

                if (Session["LoginRedirect"] == null)
                {

                    Response.Redirect("posts.aspx");
                }
                else
                {
                    Response.Redirect ((string) Session["LoginRedirect"]);
                }
            }
            else
            {
                Label1.Text = "Invalid username or password!";
            }

        }

        protected void Page_Load()
        {
            TextBox1.Focus();

            if ((string)Session["Logged"] == "True")
            {
                Response.Redirect("posts.aspx");
            }


        }
    </script>

    <link type="text/css" href="MyStyles.css" rel="Stylesheet" />
</head>
<body class="nicebody">
    <form id="form1" runat="server">
        <div>
            <center>
                <table id="Dashboard" style="width: 300; position: relative; top: 200">
                    <tr>
                        <td id="Header">
                            Login
                        </td>
                    </tr>
                    <tr>
                        <td id="Content" style="padding: 20px;">
                            <span style="float: left">Username :</span>
                            <asp:TextBox ID="TextBox1" Text="" runat="server" Style="width: 150px; font-size: 11px;
                                font-family: verdana; padding: 3px; float: right" />
                            <br />
                            <hr />
                            <span style="float: left">Password :</span>
                            <asp:TextBox ID="TextBox2" Text="" TextMode="Password" runat="server" Style="width: 150px;
                                font-size: 11px; font-family: verdana; padding: 3px; float: right" /><br />
                            <hr />
                            <asp:Button ID="Button1" Text="Login" OnClick="Button1_Click" Style="font-family: Verdana;
                                font-size: 11px; padding: 3; width: 80; float: right;" runat="server" />
                        </td>
                    </tr>
                </table>
                <asp:Label ID="Label1" Text="" runat="server" Font-Bold="true" ForeColor="Red" />
            </center>
        </div>
    </form>
</body>
</html>
