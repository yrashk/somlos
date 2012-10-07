defprotocol Somlos.Step do
  @only [Record]
  def instruction(step)
  def reverse(step)
end