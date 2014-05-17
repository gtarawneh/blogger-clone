<%@ Page Language="C#" MasterPageFile="~/Dashboard/MasterPage.master" Title="Blog Comments" %>

<%@ Import Namespace="System.Data.OleDb" %>

<script type="text/C#" runat="server">

    protected void Page_Load()
    {

        string post_id = (string)Request["id"];

        string view_opts = (string)Request["view"];

        // Creating and initializing data acess objects

        OleDbConnection Con = (OleDbConnection)Application["Con"];

        OleDbCommand Com = new OleDbCommand();

        Com.Connection = Con;

        bool com_visible_cond = (view_opts ==null);

        if (post_id == null)
        {
            if (view_opts == null)
            {
                Session["Section-Title"] = Session["Section"] = "Blog Comments";

            }
            else
            {
                // View spam only!

                Session["Section-Title"] = Session["Section"] = "Spam Comments";

            }

            Com.CommandText = "select count(*) as C from Comments where ComVisible=" + com_visible_cond.ToString();

        }
        else
        {
            Com.CommandText = "select PostTitle from posts where PostId=" + post_id;

            string post_title = (string)Com.ExecuteScalar();

            Session["Section"] = "Comments on '" + post_title + "'";

            Session["Section-Title"] = "Comments on '" + post_title + "'";

            Com.CommandText = "select count(*) as C from comments where ComPostID=" + post_id + " and ComVisible=" + com_visible_cond.ToString ();
        }

        OleDbDataReader R;

        // Processing page

        int CommentCount = (int)Com.ExecuteScalar();

        int Comments_Per_Page = 10;

        int Pages = (int)Math.Ceiling((double)CommentCount / Comments_Per_Page);

        int Selected_Page = Convert.ToInt32(Request["page"]);

        if (Selected_Page == 0) Selected_Page = 1;

        //Session["PostsPage"] = "posts.aspx?page=" + Convert.ToString(Selected_Page);

        Label2.Text = "( Page " + Convert.ToString(Selected_Page) + " of " + Convert.ToString(Pages) + ")";

        if (Selected_Page < Pages)
        {
            // Enabling Next Page link

            HyperLink2.Visible = true;
            HyperLink2.NavigateUrl = "comments.aspx?page=" + Convert.ToString(Selected_Page + 1);
            if (post_id != null) HyperLink2.NavigateUrl += "&id=" + post_id;
            if (view_opts != null) HyperLink2.NavigateUrl += "&view=" + view_opts;
        }
        else
        {
            HyperLink2.Visible = false;
        }

        if (Selected_Page != 1)
        {
            // Enabling Previous Page link

            HyperLink1.Visible = true;
            HyperLink1.NavigateUrl = "comments.aspx?page=" + Convert.ToString(Selected_Page - 1);
            if (post_id != null) HyperLink1.NavigateUrl += "&id=" + post_id;
            if (view_opts != null) HyperLink1.NavigateUrl += "&view=" + view_opts;
        }
        else
        {
            HyperLink1.Visible = false;
        }

        int Skipped_Comments = (Selected_Page - 1) * Comments_Per_Page;

        if (Skipped_Comments > 0)
        {
            if (post_id == null)
            {

                Com.CommandText = "SELECT TOP " + Convert.ToString(Comments_Per_Page) + " Comments.*, PostTitle from Comments left join Posts on Comments.ComPostID=Posts.PostID where ComID Not In (select top " + Convert.ToString(Skipped_Comments) + " ComID from Comments where ComVisible=" + com_visible_cond.ToString () + " order by ComDate desc) and ComVisible=" + com_visible_cond.ToString ()+ "   order by ComDate desc;";
            }
            else
            {
                Com.CommandText = "SELECT TOP " + Convert.ToString(Comments_Per_Page) + " Comments.*, PostTitle from Comments left join Posts on Comments.ComPostID=Posts.PostID where ComID Not In (select top " + Convert.ToString(Skipped_Comments) + " ComID from Comments where ComPostID=" + post_id + " and ComVisible=" + com_visible_cond.ToString ()+" order by ComDate desc) and Comments.ComPostID=" + post_id + " and ComVisible="  +com_visible_cond.ToString ()+ " order by ComDate desc;";
            }
        }
        else
        {
            if (post_id == null)
            {

                Com.CommandText = "SELECT TOP " + Convert.ToString(Comments_Per_Page) + " Comments.*, PostTitle from Comments left join Posts on Comments.ComPostID=Posts.PostID where ComVisible=" + com_visible_cond.ToString ()+ " order by ComDate desc;";
            }
            else
            {
                Com.CommandText = "SELECT TOP " + Convert.ToString(Comments_Per_Page) + " Comments.*, PostTitle from Comments left join Posts on Comments.ComPostID=Posts.PostID where ComPostID=" + post_id + " and ComVisible=" + com_visible_cond.ToString () +" order by ComDate desc;";
            }
        }

        R = Com.ExecuteReader();

        Rep1.DataSource = R;

        Rep1.DataBind();

        R.Close();

        Session["CancelPage"] = Request.Url.ToString();

    }

    protected string GenerateComPoster(Object x)
    {
        string result = DataBinder.Eval(x, "ComPoster").ToString();

        if (DataBinder.Eval(x, "ComVisible").ToString() == "False") result = "<i><b>" + result + "</b></i>";

        return result;

    }

</script>

<asp:Content ID="Content1" runat="server" ContentPlaceHolderID="ContentPlaceHolder1">
    <asp:Repeater ID="Rep1" runat="server">
        <HeaderTemplate>
            <table id="PostsTable">
                <tr id="HeaderRow">
                    <td class="TitleCell" style="width: 200">
                        Author
                    </td>
                    <td>
                        Post
                    </td>
                    <td style="width: 150;">
                        <center>
                            Details</center>
                    </td>
                    <td style="width: 200">
                        <center>
                            Date</center>
                    </td>
                    <td style="width: 100;">
                        <center>
                            Delete</center>
                    </td>
                </tr>
        </HeaderTemplate>
        <ItemTemplate>
            <tr>
                <td class="TitleCell">
                    <span class="Comment">
                        <%#GenerateComPoster(Container.DataItem )%></span>
                    <td>
                        <%#DataBinder.Eval(Container.DataItem, "PostTitle")%>
                    </td>
                    <td>
                        <center>
                            <a href="dcomments.aspx?id=<%#DataBinder.Eval(Container.DataItem, "ComID")%>"><span
                                class="DetailsLink">View Full Details</span></a>
                        </center>
                    </td>
                    <td>
                        <center>
                            <%#DataBinder.Eval(Container.DataItem, "ComDate")%></center>
                    </td>
                    <td>
                        <center>
                            <a href="dcomments.aspx?id=<%#DataBinder.Eval(Container.DataItem, "ComID")%>&action=delete">
                                <span class="DeleteLink">Delete</span></a>
                        </center>
                    </td>
                </td>
            </tr>
        </ItemTemplate>
        <AlternatingItemTemplate>
            <tr class="OddRow">
                <td class="TitleCell">
                    <span class="Comment">
                        <%#GenerateComPoster(Container.DataItem )%></span>
                    <td>
                        <%#DataBinder.Eval(Container.DataItem, "PostTitle")%>
                    </td>
                    <td>
                        <center>
                            <a href="dcomments.aspx?id=<%#DataBinder.Eval(Container.DataItem, "ComID")%>"><span
                                class="DetailsLink">View Full Details</span></a>
                        </center>
                    </td>
                    <td>
                        <center>
                            <%#DataBinder.Eval(Container.DataItem, "ComDate")%></center>
                    </td>
                    <td>
                        <center>
                            <a href="dcomments.aspx?id=<%#DataBinder.Eval(Container.DataItem, "ComID")%>&action=delete">
                                <span class="DeleteLink">Delete</span></a>
                        </center>
                    </td>
                </td>
            </tr>
        </AlternatingItemTemplate>
        <FooterTemplate>
            </table>
        </FooterTemplate>
    </asp:Repeater>
    <br />
    <table style="width: 900px; font-size: 11px;">
        <tr>
            <td style="text-align: left; width: 33%">
                <asp:HyperLink ID="HyperLink1" runat="server"><span class ="PreviousPage">Previous Page</span></asp:HyperLink>
            </td>
            <td style="text-align: center">
                <asp:Label ID="Label2" runat="server" Text="(Page 1 of 8)"></asp:Label>
            </td>
            <td style="text-align: right; width: 33%">
                <asp:HyperLink ID="HyperLink2" runat="server" NavigateUrl=""><span class ="NextPage">Next Page</span></asp:HyperLink>
            </td>
        </tr>
    </table>
</asp:Content>
