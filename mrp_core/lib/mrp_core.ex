defmodule MrpCore do
  def create_order(product_name) do
    product = %{id: 1, product_name: product_name}
    {:ok, product}
  end

  def product_exist_in_stock("Cadeira de Madeira") do
    true
  end

  def product_exist_in_stock(_) do
    false
  end

  def create_production_order(product_name) do
    product = %{id: 1, product_name: product_name}
    {:ok, product}
  end

  def material_exist_in_stock("tábuas", 20) do
    true
  end

  def material_exist_in_stock("parafusos", 80) do
    true
  end

  def material_exist_in_stock("colas", 10) do
    true
  end

  def material_exist_in_stock(_, _) do
    false
  end

  def get_recipe_for_product("Cadeira de Madeira") do
    recipe = %{
      id: 1,
      list_of_materials: [
        %{name: "tábuas", quantity: 20},
        %{name: "parafusos", quantity: 80},
        %{name: "colas", quantity: 10}
      ]
    }

    {:ok, recipe}
  end

  def get_recipe_for_product("Cadeira de Madeira 3") do
    recipe = %{
      id: 3,
      list_of_materials: [
        %{name: "tábuas", quantity: 30},
        %{name: "parafusos", quantity: 90},
        %{name: "colas", quantity: 20}
      ]
    }

    {:ok, recipe}
  end

  def get_recipe_for_product(_) do
    {:error, "not found recipe"}
  end

  def create_material_buy_order("tábuas", quantity, material_buy_order_id: order_id) do
    material_buy_order = %{id: order_id, product_name: "parafusos", quantity: quantity}
    {:ok, material_buy_order}
  end

  def create_material_buy_order("parafusos", quantity, material_buy_order_id: order_id) do
    material_buy_order = %{id: order_id, product_name: "parafusos", quantity: quantity}
    {:ok, material_buy_order}
  end

  def create_material_buy_order("colas", quantity, material_buy_order_id: order_id) do
    material_buy_order = %{id: order_id, product_name: "colas", quantity: quantity}
    {:ok, material_buy_order}
  end

  def create_material_buy_order(_, _, _) do
    {:error, "material not found"}
  end

  def send_material_buy_order(material_buy_order_id) do
    {:ok,
     %{
       id: 1,
       external_id: 1,
       material_buy_order_id: material_buy_order_id,
       status: "created"
     }}
  end

  def receive_material_buy_order(material_buy_order_id) do
    {:ok,
     %{
       id: 1,
       external_id: 1,
       material_buy_order_id: material_buy_order_id,
       status: "received"
     }}
  end

  def check_list_of_material_in_stock(list_of_materials) do
    missing_materials =
      Enum.filter(list_of_materials, fn material ->
        not material_exist_in_stock(material.name, material.quantity)
      end)

    if Enum.empty?(missing_materials) do
      # Todos os materiais estão em estoque
      {:ok, true}
    else
      # Retorna os materiais que faltam
      {:error, {:missing_materials, missing_materials}}
    end
  end

  def find_production_order(product_name) do
    {:ok, %{id: 1, product_name: product_name}}
  end

  def create_missign_materials_buy_order(missing_materials, material_buy_order_id: order_id) do
    result =
      Enum.map(missing_materials, fn material ->
        {:ok, material} =
          create_material_buy_order(material.name, material.quantity,
            material_buy_order_id: order_id
          )

        material
      end)

    {:ok, result}
  end
end
