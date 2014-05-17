<%@ Page Language="C#" MasterPageFile="~/Dashboard/MasterPage.master" Title="Blog Comment" %>

<%@ Import Namespace="System.Data.OleDb" %>

<script type="text/C#" runat="server">

    protected void Page_Load()
    {
        Session["Section"] = "View Comment Details";

        Session["Section-Title"] = "View Comment Details";

        // Creating and initializing data acess objects

        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand();

        //Com.CommandText = "select count(*) as C from comments";

        Com.Connection = Con;

        string comid = (string)Request["id"];

        string action = (string)Request["action"];
        
        if (comid == null) return; // Error!

        if (action == "safe")
        {
            Com.CommandText = "update Comments set ComVisible=1 where ComID=" + comid;
            Com.ExecuteNonQuery();
        }

        if (action == "unsafe")
        {
            Com.CommandText = "update Comments set ComVisible=0 where ComID=" + comid;
            Com.ExecuteNonQuery();
        }
            

        Com.CommandText = "select * from Comments inner join Posts on Comments.ComPostID=Posts.PostID where ComID=" + comid;

        OleDbDataReader R;

        R = Com.ExecuteReader();

        string comment_date = "";

        string com_postid = "";

        while (R.Read())
        {
            Label1.Text = (string)R["ComPoster"];

            Label3.Text = ((DateTime)R["ComDate"]).ToString ("dddd, MMMM dd, yyyy") ;

            Label4.Text = Convert.ToString(R["PostTitle"]);

            Label5.Text = (string)R["ComIp"];

            Label6.Text = (string)R["ComBody"];

            comment_date = ((DateTime)R["ComDate"]).ToString("dd MMM yyyy hh:mm:ss tt");

            com_postid = Convert.ToString((int)R["ComPostId"]);

            if ((bool)R["ComVisible"] == false)
            {
                HyperLink6.Visible = true;
                HyperLink6.NavigateUrl = "dcomments.aspx?id=" + comid + "&action=safe";
                HyperLink6.Text = "(Not Spam)";
            }
            else
            {
                HyperLink6.Visible = true;
                HyperLink6.NavigateUrl = "dcomments.aspx?id=" + comid + "&action=unsafe";
                HyperLink6.Text = "(Mark as Spam)";
            }
                
            
        }

        R.Close();

        Com.CommandText = "select top 1 * from Comments where ComPostID=" + com_postid + " and ComDate >CVDate('" + comment_date + "');";

        R = Com.ExecuteReader();

        while (R.Read())
        {
            string next_comment_id = Convert.ToString((int)R["ComId"]);

            HyperLink2.NavigateUrl = "dcomments.aspx?id=" + next_comment_id;

            HyperLink2.Visible = true;
        }

        R.Close();

        Com.CommandText = "select * from Comments where ComPostID=" + com_postid + " and ComDate <CVDate('" + comment_date + "') order by ComDate;";

        R = Com.ExecuteReader();

        while (R.Read())
        {
            string next_comment_id = Convert.ToString((int)R["ComId"]);

            HyperLink1.NavigateUrl = "dcomments.aspx?id=" + next_comment_id;

            HyperLink1.Visible = true;
        }

        R.Close();

        string return_page = "comments.aspx?id=" + com_postid;

        if (Session["CancelPage"] != null) return_page = (string)Session["CancelPage"];

        HyperLink3.NavigateUrl = return_page  ;
        
        Com.CommandText = "select count(*) as C from Comments where ComPostID=" + com_postid + " and ComDate <CVDate('" + comment_date + "');";

        int com_position = (int)Com.ExecuteScalar();

        Com.CommandText = "select count(*) as C from Comments where ComPostID=" + com_postid;

        int com_count = (int)Com.ExecuteScalar();

        Label7.Text = "Comment " + Convert.ToString(com_position + 1) + " of " + Convert.ToString(com_count) ;

        if ((string)Request["action"] == "delete")
        {
            tr1.Visible = false;
            tr2.Visible = true;
        }

        HyperLink4.NavigateUrl = "dcomments.aspx?id=" + comid  + "&action=delete";

        HyperLink5.NavigateUrl = "editpost.aspx?id=" + comid + "&type=comment";

    }

    protected void Button2_Click(object sender, EventArgs e)
    {
        Response.Redirect("dcomments.aspx?id=" + Request["id"]);
    }

    protected void Button1_Click(object sender, EventArgs e)
    {
        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand();

        Com.Connection = Con;

        Com.CommandText = "select ComPostID from Comments where ComID=" + (string)Request["id"];

        string post_id = Convert.ToString ((int) Com.ExecuteScalar());

        Com.CommandText = "delete from Comments where ComID=" + (string)Request["id"];

        Com.ExecuteNonQuery();

        Session["MsgText"] = "The comment has been deleted!";

        Session["RedirectURL"] = "comments.aspx?id=" + post_id ;

        Session["MsgButton"] = "Proceed";

        Response.Redirect("message.aspx");
    }

</script>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="ContentPlaceHolder1">

<script type ="Text/javascript" >

void Page_Load()
{
    setTimeout('window.scrollBy(0,9999);', 50);
}

</script>

    <table id="Dashboard" style="width: 900px;">
        <tr>
            <td id="Header">
                <asp:Label ID="Label7" runat="server"></asp:Label>
            </td>
        </tr>
        <tr>
            <td id="Content">
                <span style="color: #44779d; display: block; float: left; width: 150px;">Comment Author:</span>
                <asp:Label ID="Label1" runat="server"></asp:Label>
                <asp:HyperLink ID="HyperLink6" style="text-decoration :none; margin: 5px;" Visible ="false" runat ="server" ></asp:HyperLink>
                <br />
                <hr />
                <span style="color: #44779d; display: block; float: left; width: 150px;">Date Submitted:</span>
                <asp:Label ID="Label3" runat="server"></asp:Label>
                <br />
                <hr />
                <span style=" color: #44779d; display: block; float: left; width: 150px;">Submitted to
                    Post:</span>
                <asp:Label ID="Label4" runat="server"></asp:Label>
                <br />
                <hr />
                <span style="color: #44779d; display: block; float: left; width: 150px;">Originating
                    IP:</span>
                <asp:Label ID="Label5" runat="server"></asp:Label>
                <br />
                <hr />
                <br />
                <asp:Label ID="Label6" Style="width: 100%; min-height :185px; display :block ; border: none blue; border-width: 1"
                    runat="server"></asp:Label>
                <br />
                <br />
                <hr />
                <table style="width: 100%; height: 30px; text-align: center; font-size: 11px;">
                    <tr id="tr1" runat="server" visible ="true">
                        <td style="text-align: left; width: 60px;">
                            <asp:HyperLink ID="HyperLink5" runat ="server" ><span class="EditLink">Edit</span></asp:HyperLink> 
                        </td>
                        
                        <td style="text-align: left; width: 70px;">
                            <asp:HyperLink ID="HyperLink4" runat ="server" ><span class="DeleteLink">Delete</span></asp:HyperLink> 
                        </td>
                        <td style="text-align: left ; width :200px;">
                        <asp:HyperLink ID="HyperLink3" runat ="server" > <span class="TableViewLink">Tabular View</span></asp:HyperLink>
                        </td>
                        <td style="text-align: right">
                            <asp:HyperLink ID="HyperLink1" runat="server" Visible="false"><span class ="PreviousPage">Previous Comment in Post</span></asp:HyperLink></td>
                        <td style="text-align: center; width: 30px;">
                            
                        </td>
                        <td style="width: 150px; text-align: right">
                            <asp:HyperLink ID="HyperLink2" runat="server" Visible="false"><span class ="NextPage">Next Comment in Post</span></asp:HyperLink></td>
                    </tr>
                    <tr id="tr2" runat ="server" visible ="false" >
                    <td style ="text-align:left ">
                    Are you sure you want to delete this comment?
                    <asp:Button ID="Button1" style="margin-left:10px ;width:50px" runat="server" Text ="Yes"   OnClick ="Button1_Click"/>
                    <asp:Button ID="Button2" style="margin-left:10px ;width:50px" runat="server" Text ="No"  OnClick ="Button2_Click"/>
                    
                    </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</asp:Content>
