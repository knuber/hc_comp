

<?php
	$uid = $_GET["uid"];
	$pwd = $_GET["pwd"];
	$query = $_GET["sql"];
	if($query)
	{       
		//echo "--triggered--";
		//$con = odbc_connect("Driver=SQL Server;Server=MID-SQL02;UID=PTrowbridge;Trusted_Connection=Yes;DATABASE=FAnalysis", $uid, $pwd);
		$con = odbc_connect("Driver={iSeries Access ODBC Driver};System=S7830956", $uid, $pwd,SQL_CUR_USE_ODBC);
		//$con = db2_connect("DATABASE=S7830956;HOSTNAME=S7830956;PROTOCOL=TCPIP;UID=$uid;PWD=$pwd");
		//echo "--connected--"; 
		if (!$con){
			echo odbc_errormsg($con);
		} else {
			$result = odbc_exec($con, $query);
			if ($result){
				//echo "--get headers--";
				//echo odbc_result_all($result);
				echo "<tr>";
				for ($i=1;$i <= odbc_num_fields($result);$i++){
					echo "<td>" . odbc_field_name($result,$i) . "</td>";
				}
				echo "</tr>";
				while($row = odbc_fetch_array($result))
				{
					echo "<tr>";
					foreach($row as $i){
						echo "<td>" . $i . "</td>";
					}
					echo "</tr>";
				}
			} else {
				echo "--return_fail--";
				echo odbc_error();
			}
			odbc_close($con);
		}
	}
?>









