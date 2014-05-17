### Blogging Engine

This is a functional clone of an ex-version of the blogging engine used by Blogger.com. I created this to migrate my personal blog from Blogger.com to a personal server when it dropped support for 3rd party commenting systems (including one which I was using at the time).

The current code uses an Access database as a backend and a trivial form of authentication. These must be replaced with your own RDBMS database and secure authentication mechanism.

#### Features

* RSS feeds
* Basic user tracking (cookies + IP)
* Spam filters
* WYSIWYG post and comment editor
* Virtual post links
* Page caching
* Email notifications

#### Supported Tags

* Header and Metadata:

	* <$BlogMetaData$>
	* <$BlogPageTitle$>
	* <$BlogURL$>

* Posts:

	* <$BlogItemNumber$>
	* <$BlogItemTitle$>
	* <$BlogDateHeaderDate$>
	* <$BlogItemBody$>
	* <$BlogItemPermalinkURL$>
	* <$BlogItemCommentCount$>

* Comments:

	* <$BlogCommentDateTime$>
	* <$BlogCommentAuthor$>
	* <$BlogCommentBody$>

* Section Wrappers:

	* \<Blogger\>
	* \<BlogItemCommentsEnabled\>
	* \<ItemPage\>
	* \<BlogItemTitle\>
	* \<MainOrArchivePage\>
	* \<BlogItemComments\>
	* \<BlogCommentNewest\>

#### Dashboard Screenshot

![Screenshot](https://raw.github.com/gtarawneh/blogger-clone/master/Screenshots/screenshot.png "Screenshot")

