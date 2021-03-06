<?php
###############################################################################
# ASTPP - Open Source VoIP Billing Solution
#
# Copyright (C) 2016 iNextrix Technologies Pvt. Ltd.
# Samir Doshi <samir.doshi@inextrix.com>
# ASTPP Version 3.0 and above
# License https://www.gnu.org/licenses/agpl-3.0.html
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
class Payment extends MX_Controller {

  function Payment() {
      parent::__construct();
      $this->load->helper('template_inheritance');
      $this->load->library('session');
      $this->load->library('encrypt');
      $this->load->helper('form');

  }

  function index(){
      $account_data = $this->session->userdata("accountinfo");
      $data["accountid"] = $account_data["id"];
      $data["accountid"] = $account_data["id"];
      $data["page_title"] = "Recharge";      
      
       $system_config = common_model::$global_config['system_config'];
       if($system_config["paypal_mode"]==0){
           $data["paypal_url"] = $system_config["paypal_url"];
           $data["paypal_email_id"] = $system_config["paypal_id"];
       }else{
           $data["paypal_url"] = $system_config["paypal_sandbox_url"];
           $data["paypal_email_id"] = $system_config["paypal_sandbox_id"];
       }
       $data["paypal_tax"] = $system_config["paypal_tax"];

       $data["from_currency"] = $this->common->get_field_name('currency', 'currency', $account_data["currency_id"]);
       $data["to_currency"] = Common_model::$global_config['system_config']['base_currency'];
       $this->load->view("user_payment",$data);
  }
  
  function convert_amount($amount){
       $amount = $this->common_model->add_calculate_currency($amount,"","",true,false);
       echo number_format($amount,2);
  }
}
?> 
