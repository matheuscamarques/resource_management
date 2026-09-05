defmodule MrpCoreTest do
  use ExUnit.Case
  doctest MrpCore

  # Planejamento de Necessidades de Materiais, ou MRP (Material Requirements Planning)
  #
  # Produto: Cadeira de Madeira
  # Receita: 2 tábuas de madeira, 8 parafusos, 1 cola
  # Ordem de produção: 10 cadeiras
  # Necessidade total: 20 tábuas, 80 parafusos, 10 colas
  #
  # 1. Faço pedido de uma "Cadeira de Madeira"
  # 2. O sistema verifica a receita e calcula a necessidade total de materiais
  # 3. O sistema verifica o estoque atual de materiais
  # 4. O sistema compara a necessidade total com o estoque atual
  # 5. Se houver materiais suficientes, o sistema libera a produção
  # 6. Se faltar algum material, o sistema bloqueia a produção ou abre requisição de compra.
  #
  # Se faltar madeira, o sistema bloqueia a produção ou abre requisição de compra.
  # Primeiro cria-se a ordem, depois criamos uma order de produção.
  # Temos o produto em estoque ?
  # Não ? Então, precisamos criar uma ordem de produção para o produto.
  # Não temos materiais em stock ?
  # Criamos uma ordem de compra para os materiais necessários.
  #

  # Janela de pedidos() -> processamos. Janela de pedido de produção D+1.
  # Just-In-Time
  describe "Create a order" do
    test "should create a order" do
      # seria um anti padrao ? chame primaria nao se chamer "id"
      assert {:ok, %{id: order_id}} = MrpCore.create_order("Cadeira de Madeira")
      assert order_id >= 0
    end

    test "should return true if the product exist in stock" do
      assert MrpCore.product_exist_in_stock("Cadeira de Madeira")
    end

    test "should return false if the product does not exist in stock" do
      refute MrpCore.product_exist_in_stock("Cadeira de Metal")
    end

    test "should create production_order" do
      assert {:ok, %{id: production_order_id}} =
               MrpCore.create_production_order("Cadeira de Madeira")

      assert production_order_id >= 0
    end

    test "should return true if material exist in stock" do
      assert MrpCore.material_exist_in_stock("tábuas", 20)
      assert MrpCore.material_exist_in_stock("parafusos", 80)
      assert MrpCore.material_exist_in_stock("colas", 10)
    end

    test "should return false if material does not exist in stock" do
      refute MrpCore.material_exist_in_stock("tábuas", 21)
      refute MrpCore.material_exist_in_stock("parafusos", 81)
      refute MrpCore.material_exist_in_stock("colas", 11)
    end

    test "should create a buy_order" do
      assert {:ok, %{id: buy_order_id}} =
               MrpCore.create_material_buy_order("tábuas", 20, material_buy_order_id: 1)

      assert buy_order_id >= 0
    end

    test "The product should be needs a recipe" do
      assert {:ok, %{id: recipe_id, list_of_materials: list_of_materials}} =
               MrpCore.get_recipe_for_product("Cadeira de Madeira")

      assert recipe_id >= 0

      assert [
               %{name: "tábuas", quantity: 20},
               %{name: "parafusos", quantity: 80},
               %{name: "colas", quantity: 10}
             ] = list_of_materials
    end

    test "Should create a BuyOrder many materials in unique order" do
      assert {:ok, %{id: material_buy_order_id}} =
               MrpCore.create_material_buy_order("tábuas", 20, material_buy_order_id: 1)

      assert {:ok, %{id: ^material_buy_order_id}} =
               MrpCore.create_material_buy_order("parafusos", 80, material_buy_order_id: 1)

      assert {:ok, %{id: ^material_buy_order_id}} =
               MrpCore.create_material_buy_order("colas", 10, material_buy_order_id: 1)
    end

    test "Should create SendedBuyOrder" do
      assert {:ok,
              %{
                id: id,
                external_id: external_id,
                material_buy_order_id: material_buy_order_id,
                status: "created"
              }} =
               MrpCore.send_material_buy_order(material_buy_order_id: 1)

      assert id >= 0
      assert external_id >= 0
      assert material_buy_order_id >= 0
    end

    test "Should receive a Material from a BuyOrder" do
      assert {:ok,
              %{
                id: id,
                external_id: external_id,
                material_buy_order_id: material_buy_order_id,
                status: "received"
              }} =
               MrpCore.receive_material_buy_order(material_buy_order_id: 1)

      assert id >= 0
      assert external_id >= 0
      assert material_buy_order_id >= 0
    end
  end

  describe "Run full process" do
    test "Create a ordem de produção de uma Cadeira de Madeira onde os materiais estão em estoque" do
      result =
        with false <- MrpCore.product_exist_in_stock("Cadeira de Madeira 2"),
             {:ok, %{list_of_materials: list_of_materials}} <-
               MrpCore.get_recipe_for_product("Cadeira de Madeira"),
             {:ok, true} <-
               MrpCore.check_list_of_material_in_stock(list_of_materials),
             {:ok, production_order} <- MrpCore.create_production_order("Cadeira de Madeira 2") do
          {:ok, production_order}
        else
          unknown_behaviour -> {:error, unknown_behaviour}
        end

      assert {:ok, %{}} = result
    end
  end

  test "Criar caso em que o produto ja esta em estoque, ou seja. Ja foi produzido." do
    result =
      with true <- MrpCore.product_exist_in_stock("Cadeira de Madeira"),
           {:ok, production_order_id} = MrpCore.find_production_order("Cadeira de Madeira") do
        {:ok, production_order_id}
      else
        unknown_behaviour -> {:error, unknown_behaviour}
      end

    assert {:ok, %{}} = result
  end

  # no futuro podemos decidir se fazermos order de compra de todos os materiais ou apenas a diferença.
  test "Criar um caso onde que o produto nao esta em estoque e tem materiais faltantes" do
    result =
      with false <- MrpCore.product_exist_in_stock("Cadeira de Madeira 3"),
           {:ok, %{list_of_materials: list_of_materials}} <-
             MrpCore.get_recipe_for_product("Cadeira de Madeira 3"),
           {:error, {:missing_materials, missing_materials}} <-
             MrpCore.check_list_of_material_in_stock(list_of_materials),
           {:ok, material_buy_orders} <-
             MrpCore.create_missign_materials_buy_order(missing_materials,
               material_buy_order_id: 3
             ),
           {:ok, %{id: buy_material_order_id}} <- MrpCore.send_material_buy_order(3),
           {:ok, production_order_id} <- MrpCore.create_production_order("Cadeira de Madeira 3") do
        {:ok,
         %{
           production_order_id: production_order_id,
           buy_material_order_id: buy_material_order_id,
           material_buy_orders: material_buy_orders
         }}
      else
        unknown_behaviour -> {:error, unknown_behaviour}
      end

    assert {:ok, %{}} = result
  end
end
