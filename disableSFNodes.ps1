Function waitForNodeDisabling($nodeName)
{
    while(true)
    {
        $node = Get-ServiceFabricNode -NodeName $nodeName
        if($node.status -eq [System.Fabric.Query.NodeStatus]::disabled)
        {
            Write-Host "Node is disabled"
            break
        }
        else
        {
            Write-Host "Node i not yet disableds"
            start-sleep 20
        }
    }
}

$nodes = Get-ServiceFabricNode

foreach($node in $nodes){
    <#
        This cmdlet will disable the chosen node.
        In -Intent you must choose the state you want :
        Restart
        Pause
        RemoveData
        RemoveNode
    #>
    Disable-ServiceFabricNode -NodeName $node.NodeName -Intent RemoveNode -Force
    waitForNodeDisabling -nodeName $node.NodeName
    #Once the node is disabled you can fill the script with your operation in the node
}
