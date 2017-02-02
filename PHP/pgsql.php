
<?php
	$uid = $_GET["uid"];
	$pwd = $_GET["pwd"];
	$query = $_GET["sql"];
	if($query)
	{       
    	$con = pg_connect("host=localhost user=" . $uid . " password=" . $pwd);
    	if (!$con){
    		echo pg_last_error($con);
    	} else {
    		$result = pg_query($con, $query);
    		if ($result){
				//echo json_encode(mysqli_fetch_all($result));
				
				$nf = pg_num_fields($result);
				
				echo "<tr>";
					for($i=0;$i<=$nf-1;$i++){
						echo "<td>" . strtoupper(trim(pg_field_name($result, $i))) . "</td>";
					}
				echo "</tr>";
				
				while($row = pg_fetch_array($result))
				{
					
					echo "<tr>";
						for($i=0;$i<=$nf-1;$i++){
							echo "<td>" . $row[$i] . "</td>";
						}
					echo "</tr>";
				}
    		} else {
    			
	    		echo pg_last_error($con);
    			
    		}
    	}
    	
    	pg_close($con);
	}

?>
		  
