Attribute VB_Name = "XMLExport"
Dim swApp As Object

Dim swMath As IMathUtility

'�A�N�e�B�u�ȃA�Z���u����xml�ɃG�N�X�|�[�g
Sub main()
Set swApp = Application.SldWorks
Set swMath = swApp.GetMathUtility()

Dim swModel As ModelDoc2
Set swModel = swApp.ActiveDoc
If swModel.GetType() <> swDocASSEMBLY Then
    MsgBox "���̃t�@�C���̓A�Z���u���ł͂���܂���"
    Exit Sub
End If

Dim swAsmDoc As IAssemblyDoc
Set swAsmDoc = swModel

Dim swConfMgr As IConfigurationManager
Set swConfMgr = swModel.ConfigurationManager
Dim swConf As IConfiguration
Set swConf = swConfMgr.ActiveConfiguration
Dim swRootCp As IComponent2
Set swRootCp = swConf.GetRootComponent3(True)

Dim DOMDoc As DOMDocument60
Set DOMDoc = New DOMDocument60
DOMDoc.appendChild DOMDoc.createProcessingInstruction("xml", "version=""1.0"" encoding=""UTF-8""")

Dim cpAttr As IXMLDOMAttribute
Dim cpSubNode As IXMLDOMNode


Dim RootNode As IXMLDOMNode
Set RootNode = DOMDoc.appendChild(DOMDoc.createNode(NODE_ELEMENT, "assembly", ""))

Set cpAttr = RootNode.Attributes.setNamedItem(DOMDoc.createNode(NODE_ATTRIBUTE, "name", ""))
cpAttr.nodeValue = swRootCp.Name2 'GetSelectByIDString()=""

Set cpSubNode = RootNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "path", ""))
cpSubNode.Text = swRootCp.GetPathName()

Dim ComponentsNode As IXMLDOMNode
Set ComponentsNode = RootNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "components", ""))

Dim MatesNode As IXMLDOMNode
Set MatesNode = RootNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "mates", ""))

Dim SingleComponent As Variant
For Each SingleComponent In swRootCp.GetChildren()
    Dim swComponent As IComponent2
    Set swComponent = SingleComponent

    Dim cpNode As IXMLDOMNode
    Set cpNode = ComponentsNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "component", ""))
    
    Set cpAttr = cpNode.Attributes.setNamedItem(DOMDoc.createNode(NODE_ATTRIBUTE, "name", ""))
    cpAttr.nodeValue = swComponent.GetSelectByIDString()

    Set cpSubNode = cpNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "path", ""))
    cpSubNode.Text = swComponent.GetPathName()
    
    Set cpSubNode = cpNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "configuration", ""))
    cpSubNode.Text = swComponent.ReferencedConfiguration
    
    ExportComponentProps DOMDoc, cpNode, swComponent
    ExportMates swModel, DOMDoc, MatesNode, swComponent
    
    
Next


DOMDoc.loadXML Indent.Indent(DOMDoc.xml)
DOMDoc.Save swModel.GetPathName() + ".xml"
End Sub

'2�K�w�ȏ�̃R���|�[�l���g�̏o��
Sub ExportComponentProps(DOMDoc As DOMDocument60, cpNode As IXMLDOMNode, swComponent As IComponent2)
Dim cpAttr As IXMLDOMAttribute
Dim cpSubNode As IXMLDOMNode

Set cpSubNode = cpNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "solving", ""))
cpSubNode.Text = swComponent.Solving

Set cpSubNode = cpNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "suppression", ""))
cpSubNode.Text = swComponent.GetSuppression2()

Set cpSubNode = cpNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "visible", ""))
cpSubNode.Text = swComponent.Visible

Set cpSubNode = cpNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "transform", ""))

Dim j As Integer
For j = 0 To 15
    Dim cpTransformValueNode As IXMLDOMNode
    Set cpTransformValueNode = cpSubNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "value", ""))
    cpTransformValueNode.Text = swComponent.Transform2.ArrayData(j)
Next

Set cpSubNode = cpNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "components", ""))


Dim Child As Variant
For Each Child In swComponent.GetChildren()
    Dim swChild As IComponent2
    Set swChild = Child
    
    Dim cpChildNode As IXMLDOMNode
    Set cpChildNode = cpSubNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "component", ""))
    
    Set cpAttr = cpChildNode.Attributes.setNamedItem(DOMDoc.createNode(NODE_ATTRIBUTE, "name", ""))
    cpAttr.nodeValue = swChild.GetSelectByIDString()
    
    ExportComponentProps DOMDoc, cpChildNode, swChild
Next

End Sub

'���v���̃G�N�X�|�[�g
Sub ExportMates(swModel As IModelDoc2, DOMDoc As DOMDocument60, MatesNode As IXMLDOMNode, swComponent As IComponent2)
Dim mtAttr As IXMLDOMAttribute
Dim mtNode As IXMLDOMNode
Dim mtEntNode As IXMLDOMNode
Dim mtSubNode As IXMLDOMNode

Dim swSelMgr As ISelectionMgr
Set swSelMgr = swModel.SelectionManager

Dim SingleMate As Variant
Dim swMates As Variant
swMates = swComponent.GetMates()

If IsEmpty(swMates) Then Exit Sub

For Each SingleMate In swMates
    If TypeOf SingleMate Is SldWorks.Mate2 Then
            
        Dim swMate As IMate2
        Set swMate = SingleMate
        
        Dim swMateEnt As IMateEntity2
        'Dim swMateEntRef As Object 'IMateReference
        
        '2��Component���瓯��Mate�ɃA�N�Z�X�ł��A
        '�Е�����݂��MateEntity(0)�A�����Е������MateEntity(1)�����g�ɑ����邱�ƂɂȂ�̂ŁA
        'MateEntity(0)�������ɑ�����ꍇ�̂݃G�N�X�|�[�g���邱�Ƃɂ���
        Set swMateEnt = swMate.MateEntity(0)
        Set swRefCp = swMateEnt.ReferenceComponent
        Do Until swRefCp.GetParent() Is Nothing
            Set swRefCp = swRefCp.GetParent()
        Loop
        If swApp.IsSame(swRefCp, swComponent) <> swObjectSame Then GoTo MateSkip
    
        Set mtNode = DOMDoc.createNode(NODE_ELEMENT, "mate", "")
        
        Set mtSubNode = mtNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "type", ""))
        mtSubNode.Text = swMate.Type
        
        Dim e As Integer
        For e = 0 To swMate.GetMateEntityCount() - 1
            Set swMateEnt = swMate.MateEntity(e)
            'Set swMateEntRef = swMateEnt.Reference 'APIHelp�̋L�q�ƈ���đI������Entity�Ȃǂ��Ԃ�
            
            Set mtEntNode = DOMDoc.createNode(NODE_ELEMENT, "entity", "")
            
            Dim ExportState As Boolean
            ExportState = SelType.ExportEntity(swMateEnt, mtEntNode, DOMDoc, swMath)
            If ExportState Then mtNode.appendChild mtEntNode
            
        Next
        
        ' Coincident�Ŏg�p
        Set mtSubNode = mtNode.appendChild(DOMDoc.createNode(NODE_ELEMENT, "alignment", ""))
        mtSubNode.Text = swMate.Alignment
        
        MatesNode.appendChild mtNode
    End If
    
MateSkip:
Next
End Sub
