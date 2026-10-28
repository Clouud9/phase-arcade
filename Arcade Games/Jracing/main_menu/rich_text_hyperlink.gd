extends RichTextLabel
class_name RTHyperLink

func _ready()-> void:
    meta_clicked.connect(url_handle)

func url_handle(url:String)-> void: OS.shell_open(url)
