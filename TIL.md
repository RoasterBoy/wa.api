# TIL - Things I've learned

##  Excel and Academic Years
Formula to identify the Academic Year of a date cell.

```="AY "&YEAR(DATE(YEAR(X2),MONTH(X2)-5,1))+1```
Where *X2* is the cell adjacent to this formula

## Idea for members-only content block
```.publicContentView or .memberContentView``` is what you'll need for the CSS selector along with your custom element's class like...
```.membersOnly {display:none;}```
```.memberContentView .membersOnly {display:block;}```

See ```var bonaPage_PageView = { isAnonymousView : false,isMemberView : true,isAdminView : false };``` on logged-in page type.

## Zoom metrics

Can't use ```https://api.zoom.us/v2/metrics/meetings``` to retrieve future sessions. Grr.

## 301 Redirects
We might want to use a 301 redirect from our WordPress hosting site to Wild Apricot so that certain links still work, such as links to managing Zoom meetings, etc. See [Google Developers SEO Guide](https://developers.google.com/search/docs/advanced/crawling/301-redirects)
More to come
Options are these:
* 301 redirect in .htaccess
* Simple link to target page, typically Courses
Need to make sure that the back button and other navigation options work well.

## Pre-filled links in Google Forms
As nice as it would be to use pre-filled links to let us set the course title and instructor names in evaluations, Forms doesn't let us restrict editing on fields, even in the pre-filled ones. So, there's a chance that the member will edit or choose something unintended.
Best to stay away from this.

## Token is expired
When ```zm``` returns results that look like this, it means that my clock is out of sync. 
```
{
  "code": 124,
    "message": "Access token is expired."
    }
```
This can happen on WSL because I don't have nts running. I can force time synchronization with the following:
```sudo ntpdate -sb time.nist.gov```
an alternative is to restart WSL.

## A tool in search of a problem
Adobe has released [Adobe PDF Embed API](https://www.adobe.io/apis/documentcloud/dcsdk/pdf-pricing.html), letting us create PDF files. This seems like a good thing, but does it do anything better that Pandoc or [wkhtmltopdf](https://wkhtmltopdf.org/)?

# Premier Pro
Premiere Pro

Open a PP project
Import video
Mark in and out

# Facebook Analytics
FA is going away in June 2021.
We can only download the past six months of data. (Go to page, click Insights, and then click Download.)

# Copying from AWS Ubuntu to local Mac
Install XQuartz, mucked around with the ssh server, and now seem to have something working.
Emacs runs in the Xwindows environment, which has its own configuration. We'll figure this out eventually.

# Course Evaluations
We don't have a current way to download evaluation results from Google Drive to AWS. As a result, the ```evals``` script needs to run on WSL.

# Stuff about JSON
Just some notes to remember
```jq '.topic, (.recording_files[] | select(.file_type == "MP4") |\
      [.recording_start, .play_url, .download_url] )' 8.json | jq -s '.'
```