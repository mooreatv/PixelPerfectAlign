for %%x in (_retail_ _classic_ _beta_ _ptr_) do (
echo Installing for %%x
xcopy /i /y PixelPerfectAlign\*.* "C:\Program Files (x86)\World of Warcraft\%%x\Interface\Addons\PixelPerfectAlign"
)
