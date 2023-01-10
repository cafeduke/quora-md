# Introduction
Automation to download all your Quora answers and save each answer as a [markdown](https://en.wikipedia.org/wiki/Markdown) file. The automation has two stages

1. Generate a text file where each line is a URL to quora answer.
2. Run automation download the answer and convert to a markdown file

# Generate URLs to answers

## Load all answers

By default Quora shall display few answers and first few lines of the answer. Scrolling to to the end of the page shall load some more answers. This task is automated as follows.

- Open your [Quora profile](https://www.quora.com/profile) in the browser (Profile Icon > Name > Answers). The link should be of the format `https://www.quora.com/profile/<profile-name>`
- Right click on the blank space > Inspect > Console
- Type the following Javascript code in the console

```javascript
var interval = setInterval(
function()
{ 
  window.scrollTo(0,document.body.scrollHeight);
}, 200); 
```

## Clear loading

Once all answers are done loading execute the following Javascript in the console

```javascript
clearInterval(interval)
```

## Get URLs to answers

Execute the following Javascript in the console to parse the HTML page to pick URLs to answers. At the end of it a new Window should open having URL per line.

```javascript
var listQ='';
var listLink = document.querySelectorAll('span.q-text.qu-whiteSpace--nowrap > span > a');
listLink.forEach (
  function(node) {
     listQ += '</br>' + node.href + '\n';
  }
);
document.write(listQ);
```

Copy the contents and save it a file say `uri.txt`

# Download answer and convert to MarkDown 

- Download the project and extract it in an empty folder

  ```bash
  > unzip <path-to-archive> -d ~/Quora/gen-md
  > cd ~/Quora/gen-md
  > chmod 755 *.sh
  ```

  

- Execute run.sh

  ```bash
  # Sample uri.txt
  > cat uri.txt
  https://www.quora.com/What-is-the-climax-of-the-Kantara-movie-Why-did-the-hero-disappear/answer/Raghu-Nandan-7
  https://www.quora.com/Do-you-think-that-IT-industry-will-move-out-of-Bangalore-gradually/answer/Raghu-Nandan-7
  https://www.quora.com/What-should-a-middle-class-student-do-follow-his-her-passion-or-go-for-a-safe-paying-average-career/answer/Raghu-Nandan-7
  https://www.quora.com/Why-does-a-man-have-to-be-financially-stable-and-not-women-before-getting-married-according-to-Indian-society/answer/Raghu-Nandan-7
  
  # Download answers
  > run.sh uri.txt md-files
  
  # List markdown files
  > ls mdfiles
  a1.md a2.md a3.md a4.md
  ```

  

# Examine Markdown

We can install [Markdown Viewer](https://chrome.google.com/webstore/detail/markdown-viewer/ckkdlimhmcjmikdlpkmbgfkaikojcbjk?hl=en) extension for chrome and open the generated markdown (`*.md`) file. The generated markdown as the following metadata

- The question answered
- Link to the answer in the quora website

![SampleMarkDown](/images/SampleMarkdown.png)

