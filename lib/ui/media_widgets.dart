
import 'package:chatwoot_sdk/data/remote/responses/csat_survey_response.dart';
import 'package:chatwoot_sdk/ui/chatwoot_chat_theme.dart';
import 'package:chatwoot_sdk/ui/chatwoot_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:url_launcher/url_launcher.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final String uri;
  const FullScreenMediaViewer({Key? key, required this.uri}) : super(key: key);

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late final Player player;
  late VideoController _controller;

  @override
  void initState() {
    super.initState();
    player = Player();
    _controller = VideoController(player);
    player.open(Media(widget.uri)); // Replace with your media URL
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Video(
              controller: _controller,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 20.0,
            right: 20.0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30.0),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}


class AudioChatMessage extends StatefulWidget {
  final ChatwootChatTheme theme;
  final types.AudioMessage message;
  final bool isMine;
  const AudioChatMessage({Key? key, required this.message, required this.isMine, required this.theme}) : super(key: key);

  @override
  _AudioChatMessageState createState() => _AudioChatMessageState();
}

class _AudioChatMessageState extends State<AudioChatMessage> {


  void playAudio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  FullScreenMediaViewer(uri: widget.message.uri,)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isMine ? widget.theme.sentMessageBodyTextStyle.color : widget.theme.receivedMessageBodyTextStyle.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play Button
          GestureDetector(
            onTap: playAudio,
            child: IconButton(
              icon: Icon(
                Icons.play_arrow,
                color: activeColor,
                size: 40,
              ),
              onPressed: playAudio,
            ),
          ),
          const SizedBox(width: 10.0),
          // Progress Slider
          Expanded(
            child: Slider(
              value: 0,
              max: 0,
              activeColor: activeColor,
              inactiveColor: Colors.grey.shade400,
              onChanged: (value) {},
            ),
          ),
          // Timer
        ],
      ),
    );
  }
}


class VideoChatMessage extends StatefulWidget {
  final ChatwootChatTheme theme;
  final types.VideoMessage message;
  final bool isMine;
  final int maxWidth;
  const VideoChatMessage({Key? key, required this.theme, required this.message, required this.isMine, required this.maxWidth}) : super(key: key);

  @override
  _VideoChatMessageState createState() => _VideoChatMessageState();
}

class _VideoChatMessageState extends State<VideoChatMessage> {
  late Player player;
  late VideoController _controller;
  double height = 500;
  void playVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  FullScreenMediaViewer(uri: widget.message.uri,)),
    );
  }

  @override
  void initState() {
    super.initState();
    player = Player();
    player.open(Media(widget.message.uri),play: false);
    _controller = VideoController(player);
    _controller.rect.addListener((){
      setState(() {
        final videoHeight = _controller.rect.value?.height ?? 0;
        final videoWidth = _controller.rect.value?.width ?? 0;
        if(videoHeight > 0 && videoWidth > 0){
          height = (videoHeight * widget.maxWidth.toDouble())/videoWidth;
        }
      });
    });
  }

  @override
  void dispose() {
    player.dispose();
    _controller.rect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: widget.maxWidth.toDouble(),
      child: Stack(
        children: [
          Video(controller: _controller),
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: playVideo,
                child: Container(
                  height: 60.0,
                  width: 60.0,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class TextChatMessage extends StatefulWidget {
  final ChatwootChatTheme theme;
  final types.TextMessage message;
  final bool isMine;
  final int maxWidth;
  final void Function(types.TextMessage,types.PreviewData) onPreviewFetched;
  const TextChatMessage({
    Key? key,
    required this.theme,
    required this.message,
    required this.isMine,
    required this.maxWidth,
    required this.onPreviewFetched
  }) : super(key: key);

  @override
  _TextChatMessageState createState() => _TextChatMessageState();
}

class _TextChatMessageState extends State<TextChatMessage> {

  @override
  Widget build(BuildContext context) {
    final styleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
    final textColor = widget.isMine ? widget.theme.sentMessageBodyTextStyle.color: widget.theme.receivedMessageBodyTextStyle.color;

    return LinkPreview(
      enableAnimation: true,
      metadataTextStyle: widget.theme.receivedMessageBodyLinkTextStyle,
      metadataTitleStyle: widget.theme.receivedMessageBodyBoldTextStyle,
      onLinkPressed: (link){
        launchUrl(Uri.parse(link));
      },
      openOnPreviewImageTap: true,
      openOnPreviewTitleTap: true,
      onPreviewDataFetched: (data){
        widget.message.metadata?['previewData'] = data;
        widget.onPreviewFetched(widget.message, data);
      },
      padding: EdgeInsets.symmetric(
        horizontal: widget.theme.messageInsetsHorizontal,
        vertical: widget.theme.messageInsetsVertical,
      ),
      previewData: widget.message.metadata?["previewData"],
      text: widget.message.text,
      textWidget: MarkdownBody(
          data: widget.message.text,
          onTapLink: (text,href,title){
            if(href != null){
              launchUrl(Uri.parse(href));
            }
          },
          styleSheet: styleSheet.copyWith(
            code: widget.isMine ? widget.theme.sentMessageBodyCodeTextStyle: widget.theme.receivedMessageBodyCodeTextStyle,
            p: widget.isMine ? widget.theme.sentMessageBodyTextStyle: widget.theme.receivedMessageBodyTextStyle,
            h1: styleSheet.h1?.copyWith(color: textColor),
            h2: styleSheet.h2?.copyWith(color: textColor),
            h3: styleSheet.h3?.copyWith(color: textColor),
            h4: styleSheet.h4?.copyWith(color: textColor),
            h5: styleSheet.h5?.copyWith(color: textColor),
            h6: styleSheet.h6?.copyWith(color: textColor),
            tableBody: styleSheet.tableBody?.copyWith(color: textColor),
            tableHead: styleSheet.tableHead?.copyWith(color: textColor),
            a: widget.isMine ? widget.theme.sentMessageBodyLinkTextStyle: widget.theme.receivedMessageBodyLinkTextStyle,
          )
      ),
      userAgent: "flutter",
      width: widget.maxWidth.toDouble(),
    );
  }
}




class CSATChatMessage extends StatefulWidget {

  final ChatwootChatTheme theme;
  final ChatwootL10n l10n;
  final types.CustomMessage message;
  final int maxWidth;
  final void Function(int,String) sendCsatResults;
  const CSATChatMessage({
    Key? key,
    required this.theme,
    required this.message,
    required this.l10n,
    required this.maxWidth,
    required this.sendCsatResults
  }) : super(key: key);

  @override
  _CSATChatMessageState createState() => _CSATChatMessageState();
}

class _CSATChatMessageState extends State<CSATChatMessage> {
  String? selectedOption;
  String? feedback;
  late List<String> options ;
  final TextEditingController feedbackController = TextEditingController();

  @override
  void initState() {
    options = [
      widget.l10n.csatVeryUnsatisfied,
      widget.l10n.csatUnsatisfied,
      widget.l10n.csatOK,
      widget.l10n.csatSatisfied,
      widget.l10n.csatVerySatisfied,
    ];
    super.initState();
  }
  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.maxWidth.toDouble(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            widget.l10n.csatInquiryQuestion,
            style: widget.theme.receivedMessageBodyBoldTextStyle,
          ),
          const SizedBox(height: 16.0),

          // Options
          Column(
            children: options.map((option) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOption = option;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: selectedOption == option
                        ? widget.theme.primaryColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: selectedOption == option
                          ? widget.theme.primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedOption == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selectedOption == option
                            ? widget.theme.primaryColor
                            : Colors.black,
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        option,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),

          // Feedback Field
          Container(
            color: Colors.white,
            child: TextField(
              controller: feedbackController,
              maxLines: 3,
              minLines: 3,
              decoration: InputDecoration(
                hintText: widget.l10n.csatFeedbackPlaceholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
              ),
              onChanged: (text){
                feedback = text;
              },
            ),
          ),
          const SizedBox(height: 16.0),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedOption == null
                  ? null
                  : () {
                // Handle submission
                final rating = options.indexWhere((e)=>e == selectedOption)+1;
                widget.sendCsatResults(rating, feedback??'');
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: selectedOption == null
                    ? Colors.grey
                    : widget.theme.primaryColor, // Disabled button styling
              ),
              child: Text(
                  "Send",
                style: widget.theme.sentMessageBodyTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class RecordedCsatChatMessage extends StatelessWidget{


  final ChatwootChatTheme theme;
  final ChatwootL10n l10n;
  final types.CustomMessage message;
  final int maxWidth;
  List<String> get options => [
    l10n.csatVeryUnsatisfied,
    l10n.csatUnsatisfied,
    l10n.csatOK,
    l10n.csatSatisfied,
    l10n.csatVerySatisfied,
  ];
  CsatSurveyFeedbackResponse get feedback => message.metadata!["feedback"]! as CsatSurveyFeedbackResponse;
  String get selectedOption => options[(feedback.csatSurveyResponse?.rating ?? 3)-1];
  String get feedBackText => feedback.csatSurveyResponse?.feedbackMessage??'';

  RecordedCsatChatMessage({
    Key? key,
    required this.theme,
    required this.message,
    required this.l10n,
    required this.maxWidth,
  }):super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxWidth.toDouble(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            l10n.csatThankYouMessage,
            style: theme.receivedMessageBodyBoldTextStyle,
          ),
          const SizedBox(height: 16.0),

          // Options
          Column(
            children: options.map((option) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: selectedOption == option
                      ? theme.primaryColor.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: selectedOption == option
                        ? theme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedOption == option
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selectedOption == option
                          ? theme.primaryColor
                          : Colors.grey.shade300,
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: selectedOption == option
                            ? theme.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),

          // Feedback Field
          Text(
            feedBackText,
            style: theme.receivedMessageBodyTextStyle,
          ),

        ],
      ),
    );
  }

}



