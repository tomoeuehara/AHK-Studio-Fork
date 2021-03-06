class code_explorer{
	static explore:=[],TreeView:=[],sort:=[],function:="Om`n)^\s*((\w|[^\x00-\x7F])+)\((.*)?\)[\s+;.*\s+]?[\s*]?{",label:="Om`n)^\s*((\w|[^\x00-\x7F])+):[\s+;]",functions:=[],bookmarks:=[],variables:=[],varlist:=[]
	scan(node){
		explore:=[],bits:=[],method:=[]
		for a,b in ["menu","file","label","method","function","hotkey","class","property","variable"]
			explore[b]:=[]
		filename:=ssn(node,"@file").text,parentfile:=ssn(node.ParentNode,"@file").text
		skip:=ssn(node,"@skip").text?1:0,code:=update({get:filename}),pos:=1
		if pos:=InStr(code,"/*"){
			while,pos:=RegExMatch(code,"UOms`n)^(\/\*.*\*\/)",found,pos){
				rep:=RegExReplace(found.1,"(:|\(|\))","_"),pos:=found.Pos(1)+1,rp:=found.1
				StringReplace,code,code,%rp%,%rep%,All
			}
		}
		if !v.options.Disable_Variable_List{
			pos:=1,this.variables[parentfile,filename]:=[]
			while,pos:=RegExMatch(code,"Osm`n)(\w*)(\s*)?:=",var,pos){
				if var.len(1)
					this.variables[parentfile,filename,var.1]:=1,pos:=var.Pos(1)+var.len(1)
				else
					pos+=1
			}
		}
		for type,find in {hotkey:"Om`n)^\s*([#|!|^|\+|~|\$|&|<|>|*]*?\w+)::",label:this.label}{
			pos:=1
			while,pos:=RegExMatch(code,find,fun,pos){
				np:=StrPut(SubStr(code,1,fun.Pos(1)),"utf-8")-1-(StrPut(SubStr(fun.1,1,1),"utf-8")-1)
				explore[type].Insert({type:type,file:filename,pos:np,text:fun.1,root:parentfile,order:"text,type,file"})
				pos:=fun.pos(1)+1
			}
		}
		lastpos:=pos:=1
		Loop
		{
			test:=[]
			for type,find in {class:"Om`ni)^[\s*]?(class[\s*](\w|[^\x00-\x7F])+)",function:this.function}{
				if pos:=RegExMatch(code,find,fun,pos){
					if (type="function"&&fun.1="if")
						Continue
					np:=StrPut(SubStr(code,1,fun.Pos(1)),"utf-8")-1-(StrPut(SubStr(fun.1,1,1),"utf-8")-1)
					if pos
						test[pos]:={type:type,file:filename,pos:np,text:fun.1,root:parentfile,cpos:pos,args:fun.3}
					pos:=fun.pos(1)+1
				}
				pos:=lastpos
			}
			min:=test[test.MinIndex()]
			if (min.type="class"){
				cl:=SubStr(code,min.cpos),left:="",foundone:="",count:=0
				for a,b in StrSplit(cl,"`n"){
					line:=RegExReplace(RegExReplace(b,"(\s+" Chr(59) ".*)\n"),"U)(" Chr(34) ".*" Chr(34) ")")
					RegExReplace(line,"{","",open),count+=open
					if (open&&foundone="")
						foundone:=1
					RegExReplace(line,"}","",close),count-=close
					if (count=0&&foundone)
						break
					left.=b "`n"
				}
				pos:=lastpos:=min.cpos+StrLen(left)
				explore.class.Insert({type:"class",file:filename,pos:min.pos,text:min.text,root:min.root,order:"text,type,root"})
				npos:=1
				while,npos:=RegExMatch(left,this.function,method,npos){
					np:=StrPut(SubStr(left,1,method.Pos(1)),"utf-8")-1-(StrPut(SubStr(method.1,1,1),"utf-8")-1)
					explore.Method.Insert({file:filename,pos:np+min.pos,text:method.1,args:method.value(3),class:min.text,root:min.root,type:"method",order:"text,type,file,args"})
					npos:=method.Pos(1)+1
				}
				npos:=1
				while,npos:=RegExMatch(left,"Om`n)^\s*((\w|[^\x00-\x7F])+)\[(.*)?\][\s+;.*\s+]?[\s*]?{",Property,npos){
					np:=StrPut(SubStr(left,1,Property.Pos(1)),"utf-8")-1-(StrPut(SubStr(Property.1,1,1),"utf-8")-1)
					explore.Property.Insert({file:filename,pos:np+min.pos,text:Property.1,args:Property.value(3),class:min.text,root:min.root,type:"Property",order:"text,type,file,args"})
					npos:=Property.Pos(1)+1
				}
				continue
			}else if(min.type="function"&&min.text!="if"){
				min.order:="text,type,file,args"
				explore.function.Insert(min)
				code_explorer.functions[ParentFile,min.text]:=min
			}if !(test.MinIndex())
				break
			lastpos:=pos:=test.MinIndex()+StrLen(min.text)
		}
		ubp(csc(),filename)
		pos:=fun.Pos(1)+len,this.explore[parentfile,filename]:=explore,this.skip[filename]:=skip
		bm:=bookmarks.sn("//file[@file='" filename "']/mark")
		code_explorer.bookmarks.Remove(filename)
		code_explorer.bookmarks[filename]:=[]
		while,bb:=bm.item[A_Index-1]
			ea:=bookmarks.ea(bb),code_explorer.bookmarks[filename].Insert({type:"Bookmark",text:ea.name,line:ea.line,file:filename,order:"text,type,file",root:parentfile})
	}
	remove(filename){
		this.explore.remove(ssn(filename,"@file").text)
		list:=sn(filename,"@file")
		while,ll:=list.item[A_Index-1]
			this.explore.Remove(ll.text)
	}
	populate(){
		code_explorer.Refresh_Code_Explorer()
		Gui,1:TreeView,SysTreeView321
	}
	Refresh_Code_Explorer(){
		if v.options.Hide_Code_Explorer
			return
		Gui,1:TreeView,SysTreeView322
		GuiControl,1:-Redraw,SysTreeView322
		code_explorer.scan(current()),TV_Delete(),this.treeview:=[],bookmark:=[]
		this.TreeView.filename:=[],this.TreeView.type:=[],this.TreeView.class:=[],this.TreeView.obj:=[]
		SplashTextOff
		for a,b in code_explorer.explore{
			for q,r in b{
				for c,f in r{
					for _,d in f
					{
						Gui,1:TreeView,SysTreeView322
						file:=d.root
						if this.skip[d.file]
							continue
						if this.skip[file]
							Continue
						SplitPath,file,filename
						if !this.TreeView.filename[file]
							this.TreeView.filename[file]:=TV_Add(filename,0,"Sort")
						if (c!="method"&&c!="property")
							if !item:=this.TreeView.type[file,c]
								item:=this.TreeView.type[file,c]:=TV_Add(c,this.TreeView.filename[file],"Sort")
						if (c~="(method|property)")
							this.treeview.obj[TV_Add(d.text,this.TreeView.class[file,d.class],"Sort")]:=d
						Else if (c="class")
						{
							if !this.TreeView.class[file,d.text]
								this.TreeView.obj[this.TreeView.class[file,d.text]:=TV_Add(d.text,item,"Sort")]:=d
						}
						else if (c!="method")
							this.TreeView.obj[TV_Add(d.text,item,"Sort")]:=d
					}
				}
				for a,b in code_explorer.bookmarks[q]
					bookmark.Insert(b)
			}
		}
		for a,b in bookmark{
			if A_Index=1
				root:=TV_Add("Bookmarks",0)
			this.treeview.obj[TV_Add(b.text,root,"Sort")]:=b
		}
		GuiControl,1:+Redraw,SysTreeView322
		return
		GuiContextMenu:
		ControlGetFocus,Focus,% hwnd([1])
		if (Focus="SysTreeView322"){
			GuiControl,+g,SysTreeView322
			code_explorer.Refresh_Code_Explorer()
			GuiControl,+gcej,SysTreeView322
		}
		if (Focus="SysTreeView321")
			new()
		return
	}
	cej(){
		cej:
		if (A_GuiEvent="S"&&A_GuiEvent!="RightClick"){
			list:=""
			obj:=code_explorer.TreeView.obj[A_EventInfo]
			if (obj.file){
				TV(files.ssn("//main[@file='" obj.root "']/file[@file='" obj.file "']/@tv").text)
				Sleep,200
				if (obj.type="bookmark"){
					csc().2024(obj.line)
					ControlFocus,,% "ahk_id"csc().sc
				}
				else
					csc().2160(obj.pos,obj.pos+StrPut(obj.text,"Utf-8")-1),v.sc.2169,v.sc.2400
			}
		}
		return
	}
}