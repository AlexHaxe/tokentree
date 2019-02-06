package tokentree.walk;

class WalkTypeNameDef {
	public static function walkTypeNameDef(stream:TokenStream, parent:TokenTree):TokenTree {
		WalkComment.walkComment(stream, parent);
		WalkAt.walkAts(stream);
		if (stream.is(Question)) {
			var questTok:TokenTree = stream.consumeTokenDef(Question);
			parent.addChild(questTok);
			parent = questTok;
			WalkComment.walkComment(stream, parent);
		}
		var name:Null<TokenTree>;
		var bAdd:Bool = true;
		switch (stream.token()) {
			case BrOpen:
				WalkTypedefBody.walkTypedefBody(stream, parent);
				return parent.getFirstChild();
			case BkOpen:
				WalkArrayAccess.walkArrayAccess(stream, parent);
				return parent.getFirstChild();
			case Kwd(KwdMacro), Kwd(KwdExtern), Kwd(KwdNew):
				name = stream.consumeToken();
			case Const(_):
				name = stream.consumeConst();
			case Dollar(_):
				name = stream.consumeToken();
			case POpen:
				name = WalkPOpen.walkPOpen(stream, parent);
				if (stream.is(Question)) {
					WalkQuestion.walkQuestion(stream, name);
				}
				bAdd = false;
			case Sharp(_):
				WalkSharp.walkSharp(stream, parent, WalkStatement.walkStatement);
				if (!stream.hasMore()) return parent.getFirstChild();
				switch (stream.token()) {
					case Const(_): name = stream.consumeConst();
					default: return parent.getFirstChild();
				}
			default:
				name = stream.consumeToken();
		}
		stream.applyTempStore(name);
		if (bAdd) parent.addChild(name);
		walkTypeNameDefContinue(stream, name);
		return name;
	}

	static function walkTypeNameDefContinue(stream:TokenStream, parent:TokenTree) {
		walkTypeNameDefComment(stream, parent);
		if (stream.is(Dot)) {
			var dot:TokenTree = stream.consumeTokenDef(Dot);
			parent.addChild(dot);
			WalkTypeNameDef.walkTypeNameDef(stream, dot);
			return;
		}
		if (stream.is(Binop(OpLt))) WalkLtGt.walkLtGt(stream, parent);
		if (stream.is(Arrow)) {
			var arrow:TokenTree = stream.consumeTokenDef(Arrow);
			parent.addChild(arrow);
			WalkTypeNameDef.walkTypeNameDef(stream, arrow);
			return;
		}
		if (stream.is(BkOpen)) WalkArrayAccess.walkArrayAccess(stream, parent);
		walkTypeNameDefComment(stream, parent);
	}

	static function walkTypeNameDefComment(stream:TokenStream, parent:TokenTree) {
		var currentPos:Int = stream.getStreamIndex();
		var progress:TokenStreamProgress = new TokenStreamProgress(stream);
		var comments:Array<TokenTree> = [];
		while (stream.hasMore() && progress.streamHasChanged()) {
			switch (stream.token()) {
				case Comment(_), CommentLine(_):
					comments.push(stream.consumeToken());
				case DblDot, Comma, Semicolon, Dot, BrOpen, BkOpen, POpen, Binop(_):
					for (comment in comments) {
						parent.addChild(comment);
					}
					return;
				default:
					stream.rewindTo(currentPos);
					return;
			}
		}
	}
}